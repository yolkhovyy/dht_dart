// Copyright (c) 2017, AUTHORS. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <linux/i2c-dev.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <iostream>
#include <iomanip>

#include <fstream>
#include <cstring>
#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "pi_2_dht_read.h"

float* dht_read(int model, int pin, int i2c_address) {

    float* values = nullptr;
    float humidity, temperature;
    bool success = false;

    if (model <= 22) {
        // DHT11/22
        std::ifstream ifs_humidity("/sys/kernel/dht22/humidity", std::ifstream::in);
        std::ifstream ifs_temperature("/sys/kernel/dht22/temperature", std::ifstream::in);
        if (!ifs_humidity.fail() && !ifs_temperature.fail()) {
            ifs_humidity >> humidity;
            ifs_humidity.close();
            ifs_temperature >> temperature;
            ifs_temperature.close();
            success = true;
        } else {
            int r = pi_2_dht_read(model, pin, &humidity, &temperature);
            success = r == 0;
        }
    } else if (model >= 30) {
        // SHT3x
        char *file_name = (char *)(pin == 0 ? "/dev/i2c-0" : "/dev/i2c-1");
        int fd = open(file_name, O_RDWR);
        if (fd >= 0) {
            if (ioctl(fd, I2C_SLAVE, i2c_address) == 0) {   // Set the port options and set the address of the device
                unsigned char buffer[6];
                buffer[0] = 0x2c;                           // Commands
                buffer[1] = 0x06;
                if (write(fd, buffer, 2) == 2) {            // Write commands
                    usleep(500000);                         // This sleep waits for the ping to come back
                    buffer[0] = 0;                          // The register to read from
                    if (write(fd, buffer, 1) == 1) {        // Send the register to read from
                        if (read(fd, buffer, 6) == 6) {     // Read back data into buffer
                            temperature = ((((buffer[0] * 256.0) + buffer[1]) * 175) / 65535.0) - 45;
                            humidity = ((((buffer[3] * 256.0) + buffer[4]) * 100) / 65535.0);
                            success = true;
                        }
                    }
                }
            }
            close(fd);
        }
    }

    if (success) {
        values = reinterpret_cast<float*>(malloc(2 * sizeof(float)));
        if (values != nullptr) {
            values[0] = humidity;
            values[1] = temperature;
        }
    }
    return values;
}

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope);

DART_EXPORT Dart_Handle dht_native_Init(Dart_Handle parent_library) {
    if (Dart_IsError(parent_library)) {
        return parent_library;
    }

    Dart_Handle result_code = Dart_SetNativeResolver(parent_library, ResolveName, NULL);
    if (Dart_IsError(result_code)) {
        return result_code;
    }

    return Dart_Null();
}

Dart_Handle HandleError(Dart_Handle handle) {
    if (Dart_IsError(handle)) {
        Dart_PropagateError(handle);
    }
    return handle;
}

void DHTRead(Dart_Port dest_port_id, Dart_CObject* message) {
    Dart_Port reply_port_id = ILLEGAL_PORT;
    if (message->type == Dart_CObject_kArray && message->value.as_array.length == 4) {
        // Read parameter objects
        Dart_CObject* param0 = message->value.as_array.values[0];
        Dart_CObject* param1 = message->value.as_array.values[1];
        Dart_CObject* param2 = message->value.as_array.values[2];
        Dart_CObject* param3 = message->value.as_array.values[3];
        if (param0->type == Dart_CObject_kInt32 && param1->type == Dart_CObject_kInt32 && param2->type == Dart_CObject_kInt32
                && param3->type == Dart_CObject_kSendPort) {
            int model = param0->value.as_int32;
            int pin = param1->value.as_int32;
            int i2c_address = param2->value.as_int32;
            reply_port_id = param3->value.as_send_port.id;
            float* values = dht_read(model, pin, i2c_address);
            if (values != NULL) {
                Dart_CObject result;
                result.type = Dart_CObject_kTypedData;
                result.value.as_typed_data.type = Dart_TypedData_kUint8;
                result.value.as_typed_data.length = 8;
                result.value.as_typed_data.values = reinterpret_cast<uint8_t*>(values);
                Dart_PostCObject(reply_port_id, &result);
                free(values);
                // It is OK that result is destroyed when function exits.
                // Dart_PostCObject has copied its data.
                return;
            }
        }
    }
    Dart_CObject result;
    result.type = Dart_CObject_kNull;
    Dart_PostCObject(reply_port_id, &result);
}

void DHTReadServicePort(Dart_NativeArguments arguments) {
    Dart_EnterScope();
    Dart_SetReturnValue(arguments, Dart_Null());
    Dart_Port service_port = Dart_NewNativePort("DHTReadService", DHTRead, true);
    if (service_port != ILLEGAL_PORT) {
        Dart_Handle send_port = HandleError(Dart_NewSendPort(service_port));
        Dart_SetReturnValue(arguments, send_port);
    }
    Dart_ExitScope();
}

struct FunctionLookup {
    const char* name;
    Dart_NativeFunction function;
};

FunctionLookup function_list[] = {
        { "DHTRead_ServicePort", DHTReadServicePort },
        { nullptr, nullptr }
};

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope) {
    if (!Dart_IsString(name)) {
        return NULL;
    }

    Dart_NativeFunction result = NULL;
    if (auto_setup_scope == NULL) {
        return NULL;
    }

    Dart_EnterScope();
    const char* cname;
    HandleError(Dart_StringToCString(name, &cname));

    for (int i = 0; function_list[i].name != NULL; ++i) {
        if (strcmp(function_list[i].name, cname) == 0) {
            *auto_setup_scope = true;
            result = function_list[i].function;
            break;
        }
    }

    Dart_ExitScope();
    return result;
}

