/*
 * Copyright (c) 1994, 2016, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

#include "jni.h"
#include "fdlibm.h"

#include "java_lang_StrictMath.h"

#define _JNI_FUNC_1(name, type_0, type_0_sig, type_0_call, type_1, type_1_sig, type_1_call) \
JNIEXPORT type_0 JNICALL \
Java_java_lang_StrictMath_ ## name ## __ ## type_0_sig (JNIEnv *env, jclass unused, type_0 v) { \
    return type_0_call(v); \
} \
JNIEXPORT type_1 JNICALL \
Java_java_lang_StrictMath_ ## name ## __ ## type_1_sig (JNIEnv *env, jclass unused, type_1 v) { \
    return type_1_call(v); \
}

#define _JNI_FUNC_2(name, type_0, type_0_sig, type_0_call, type_1, type_1_sig, type_1_call) \
JNIEXPORT type_0 JNICALL \
Java_java_lang_StrictMath_ ## name ## __ ## type_0_sig (JNIEnv *env, jclass unused, type_0 v0, type_0 v1) { \
    return type_0_call(v0, v1); \
} \
JNIEXPORT type_1 JNICALL \
Java_java_lang_StrictMath_ ## name ## __ ## type_1_sig (JNIEnv *env, jclass unused, type_1 v0, type_1 v1) { \
    return type_1_call(v0, v1); \
}

_JNI_FUNC_1(cos, jdouble, D, jcos, jfloat, F, jcos)
_JNI_FUNC_1(sin, jdouble, D, jsin, jfloat, F, jsin)
_JNI_FUNC_1(tan, jdouble, D, jtan, jfloat, F, jtan)
_JNI_FUNC_1(asin, jdouble, D, jasin, jfloat, F, jasin)
_JNI_FUNC_1(acos, jdouble, D, jacos, jfloat, F, jacos)
_JNI_FUNC_1(atan, jdouble, D, jatan, jfloat, F, jatan)
_JNI_FUNC_1(log, jdouble, D, jlog, jfloat, F, jlog)
_JNI_FUNC_1(log10, jdouble, D, jlog10, jfloat, F, jlog10)
_JNI_FUNC_1(sqrt, jdouble, D, jsqrt, jfloat, F, jsqrt)
_JNI_FUNC_1(cosh, jdouble, D, jcosh, jfloat, F, jcosh)
_JNI_FUNC_1(sinh, jdouble, D, jsinh, jfloat, F, jsinh)
_JNI_FUNC_1(tanh, jdouble, D, jtanh, jfloat, F, jtanh)
_JNI_FUNC_1(log1p, jdouble, D, jlog1p, jfloat, F, jlog1p)
_JNI_FUNC_1(expm1, jdouble, D, jexpm1, jfloat, F, jexpm1)
_JNI_FUNC_2(atan2, jdouble, D, jatan2, jfloat, F, jatan2)
_JNI_FUNC_2(IEEEremainder, jdouble, D, jremainder, jfloat, F, jremainder)
