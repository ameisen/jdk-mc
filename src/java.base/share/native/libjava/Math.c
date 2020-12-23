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

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_asin(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)asin((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_asinf(JNIEnv *env, jclass unused, jfloat d)
{
    return (jfloat)asinf((float)d);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_acos(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)acos((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_acosf(JNIEnv *env, jclass unused, jfloat d)
{
    return (jfloat)acosf((float)d);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_atan(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)atan((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_atanf(JNIEnv *env, jclass unused, jfloat d)
{
    return (jfloat)atanf((float)d);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_cbrt(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)cbrt((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_cbrtf(JNIEnv *env, jclass unused, jfloat d)
{
   return (jfloat)cbrtf((float)d);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_hypot(JNIEnv *env, jclass unused, jdouble d1, jdouble d2)
{
    return (jdouble)hypot((double)d1, (double)d2);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_hypotf(JNIEnv *env, jclass unused, jfloat d1, jfloat d2)
{
    return (jfloat)hypotf((float)d1, (float)d2);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_cosh(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)cosh((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_coshf(JNIEnv *env, jclass unused, jfloat d)
{
    return (jfloat)coshf((float)d);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_sinh(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)sinh((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_sinhf(JNIEnv *env, jclass unused, jfloat d)
{
    return (jfloat)sinhf((float)d);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_tanh(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)tanh((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_tanhf(JNIEnv *env, jclass unused, jfloat d)
{
    return (jfloat)tanhf((float)d);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_log1p(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)log1p((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_log1pf(JNIEnv *env, jclass unused, jfloat d)
{
    return (jfloat)log1pf((float)d);
}

JNIEXPORT jdouble JNICALL
Java_java_lang_Math_expm1(JNIEnv *env, jclass unused, jdouble d)
{
    return (jdouble)expm1((double)d);
}

JNIEXPORT jfloat JNICALL
Java_java_lang_Math_expm1f(JNIEnv *env, jclass unused, jfloat d)
{
    return (jfloat)expm1f((float)d);
}
