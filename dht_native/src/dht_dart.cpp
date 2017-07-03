// Copyright (c) 2017, AUTHORS. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

#include <iostream>
#include <cstring>
#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "pi_2_dht_read.h"

float* dht_read(int model, int pin) {
    float* values = nullptr;
    float humidity, temperature;
    int r = pi_2_dht_read(model, pin, &humidity, &temperature);
    if (r == 0) {
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
    if (message->type == Dart_CObject_kArray && message->value.as_array.length == 3) {
        // Read parameter objects
        Dart_CObject* param0 = message->value.as_array.values[0];
        Dart_CObject* param1 = message->value.as_array.values[1];
        Dart_CObject* param2 = message->value.as_array.values[2];
        if (param0->type == Dart_CObject_kInt32 && param1->type == Dart_CObject_kInt32
                && param2->type == Dart_CObject_kSendPort) {
            int model = param0->value.as_int32;
            int pin = param1->value.as_int32;
            reply_port_id = param2->value.as_send_port.id;
            float* values = dht_read(model, pin);
            if (values != NULL) {
                Dart_CObject result;
                result.type = Dart_CObject_kArray;
                result.value.as_array.length = 2;

                Dart_CObject* value0 = new Dart_CObject();
                value0->type = Dart_CObject_kDouble;
                value0->value.as_double = static_cast<double>(values[0]);
                result.value.as_array.values[0] = value0;;

                Dart_CObject* value1 = new Dart_CObject();
                value1->type = Dart_CObject_kDouble;
                value1->value.as_double = static_cast<double>(values[1]);
                result.value.as_array.values[1] = value1;

                Dart_PostCObject(reply_port_id, &result);

                free(value1);
                free(value0);
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

