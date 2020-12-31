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

#include <math.h>

#include "java_lang_Math.h"

#define _JNI_FUNC_1(name, type_0, type_0_sig, type_0_call, type_1, type_1_sig, type_1_call) \
JNIEXPORT type_0 JNICALL \
Java_java_lang_Math_ ## name ## __ ## type_0_sig ## (JNIEnv *env, jclass unused, type_0 v) { \
    return type_0_call(v); \
} \
JNIEXPORT type_1 JNICALL \
Java_java_lang_Math_ ## name ## __ ## type_1_sig ## (JNIEnv *env, jclass unused, type_1 v) { \
    return type_1_call(v); \
}

#define _JNI_FUNC_2(name, type_0, type_0_sig, type_0_call, type_1, type_1_sig, type_1_call) \
JNIEXPORT type_0 JNICALL \
Java_java_lang_Math_ ## name ## __ ## type_0_sig ## type_0_sig ## (JNIEnv *env, jclass unused, type_0 v0, type_0 v1) { \
    return type_0_call(v0, v1); \
} \
JNIEXPORT type_1 JNICALL \
Java_java_lang_Math_ ## name ## __ ## type_1_sig ## type_1_sig ## (JNIEnv *env, jclass unused, type_1 v0, type_1 v1) { \
    return type_1_call(v0, v1); \
}

_JNI_FUNC_1(sin, jdouble, D, sin, jfloat, F, sinf)
_JNI_FUNC_1(cos, jdouble, D, cos, jfloat, F, cosf)
_JNI_FUNC_1(tan, jdouble, D, tan, jfloat, F, tanf)
_JNI_FUNC_1(asin, jdouble, D, asin, jfloat, F, asinf)
_JNI_FUNC_1(acos, jdouble, D, acos, jfloat, F, acosf)
_JNI_FUNC_1(atan, jdouble, D, atan, jfloat, F, atanf)
_JNI_FUNC_1(cbrt, jdouble, D, cbrt, jfloat, F, cbrtf)
_JNI_FUNC_1(cosh, jdouble, D, cosh, jfloat, F, coshf)
_JNI_FUNC_1(sinh, jdouble, D, sinh, jfloat, F, sinhf)
_JNI_FUNC_1(tanh, jdouble, D, tanh, jfloat, F, tanhf)
_JNI_FUNC_1(exp,  jdouble, D, exp,  jfloat, F, expf)
_JNI_FUNC_1(log,  jdouble, D, log,  jfloat, F, logf)
_JNI_FUNC_1(sqrt,  jdouble, D, sqrt,  jfloat, F, sqrtf)
_JNI_FUNC_2(IEEEremainder,  jdouble, D, remainder,  jfloat, F, remainderf)
_JNI_FUNC_1(log1p, jdouble, D, log1p, jfloat, F, log1pf)
_JNI_FUNC_1(expm1, jdouble, D, expm1, jfloat, F, expm1f)
_JNI_FUNC_2(hypot, jdouble, D, hypot, jfloat, F, hypotf)
_JNI_FUNC_2(pow_native, jdouble, D, pow, jfloat, F, powf)
_JNI_FUNC_1(round, jdouble, D, round, jfloat, F, roundf)
_JNI_FUNC_1(ceil, jdouble, D, ceil, jfloat, F, ceilf)
_JNI_FUNC_1(floor, jdouble, D, floor, jfloat, F, floorf)
_JNI_FUNC_1(rint, jdouble, D, rint, jfloat, F, rintf)
_JNI_FUNC_2(atan2, jdouble, D, atan2, jfloat, F, atan2f)

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_scalb__DI(JNIEnv *env, jclass unused, jdouble v0, jint v1) {
    return scalbn(v0, v1);
}
JNIEXPORT jfloat JNICALL
Java_java_lang_Math_scalb__FI(JNIEnv *env, jclass unused, jfloat v0, jint v1) {
    return scalbnf(v0, v1);
}
