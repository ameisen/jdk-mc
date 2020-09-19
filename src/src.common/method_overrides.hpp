#pragma once

#if defined(__INTELLISENSE__)
#	include "common.h"
#endif

#include <initializer_list>

#include <cstdio>
#include <cstring>

namespace carbide::overrides {
	using namespace std;

	static bool always_precompile_method(const char * __restrict name) {
		if (_unlikely(!name)) [[unlikely]] {
			name = "<unknown>";
		}

		auto contains = [name](const char * __restrict str) {
			return strstr(name, str) != nullptr;
		};


		for (const char * __restrict str : {
			/*
			"org.objectweb.asm",
			"org.lwjgl",
			"net.optifine",
			"com.mojang.blaze3d",
			"net.minecraft.client.renderer",
			"net.minecraft.crash.CrashReport.func",
			"sun.java2d",
			"org.apache.logging",
			"it.unimi.dsi.fastutil",
			"com.google",
			" net.minecraft.entity",
			" net.minecraft.world",
			" net.minecraft.state",
			"net.minecraft.network",
			" net.minecraft.util",
			" net.minecraft.nbt",
			" net.minecraft.block",
			" net.minecraft.client.multiplayer.ClientChunkProvider",
			" net.minecraft.village.PointOfInterestManager",
			" net.minecraft.client.audio",
			" net.minecraft.client.network",
			" net.minecraftforge",
			" java.util.concurrent",
			" java.lang.invoke",
			" java.lang.reflect",
			" java.util.BitSet",
			" java.util.zip",
			" java.util.Collections",
			" java.util.Arrays",
			" java.lang.ClassLoader",
			" java.lang.Integer",
			" java.lang.Float",
			" java.lang.Double",
			" java.lang.Math",
			" java.lang.StrictMath",
			" java.lang.Thread",
			*/

			/*
			" java.lang.Number",
			" java.lang.StringCoding",
			" java.util.HashMap",
			" java.util.LinkedHashMap",
			" jdk.internal.math",
			" java.net",
			" java.nio",
			" java.util.stream",
			" java.util.OptionalInt",
			" com.mojang.serialization",
			" com.mojang.datafixers",
			" sun.reflect.misc",
			" io.netty",
			"hashCode()",
			"toString()",
			"equals(",
			"linkToCallSite",
			"close()",
			"render",
			"Render",
			"CrashReport",
			"valueOf",
			*/

			/*
			"write(",
			"charAt(",
			"getComparator",
			"checkIndex",
			"add(",
			"allocateDirect",
			"length(",
			*/

			"newBytesFor",
			//"NumberFormatException",
			//"IOException",

			"getName(",
			//"newIllegalAccessException",
			" xaero.",
			"net.minecraft.world.chunk",
		}) {
			if (contains(str)) {
				return true;
			}
		}

		string_switch(name) {
			string_case("void java.lang.Object.<init>()"):
			string_case("void java.lang.Integer.<init>(int)"):
			string_case("void java.lang.NullPointerException.<init>()"):
			string_case("void java.lang.NullPointerException.<init>(java.lang.String)"):
			string_case("void java.lang.IllegalStateException.<init>()"):
			string_case("void java.lang.IllegalStateException.<init>(java.lang.String)"):
			string_case("void java.lang.IllegalArgumentException.<init>()"):
			string_case("void java.lang.IllegalArgumentException.<init>(java.lang.String)"):
			string_case("void java.lang.UnsupportedOperationException.<init>()"):
			string_case("void java.lang.UnsupportedOperationException.<init>(java.lang.String)"):
			string_case("java.lang.RuntimeException java.lang.invoke.MethodHandleStatics.newIllegalArgumentException(java.lang.String)"):
			string_case("boolean java.util.AbstractMap.equals(java.lang.Object)"):
			string_case("java.lang.Object java.lang.ref.Reference.get()"):
			string_case("void java.lang.ClassLoader.addClass(java.lang.Class)"):
			string_case("java.lang.invoke.MethodHandle java.lang.invoke.MethodHandleNatives.linkMethodHandleConstant(java.lang.Class, int, java.lang.Class, java.lang.String, java.lang.Object)"):
			string_case("java.lang.invoke.MemberName java.lang.invoke.MethodHandleNatives.linkCallSite(java.lang.Object, int, java.lang.Object, java.lang.Object, java.lang.Object, java.lang.Object, java.lang.Object[])"):
			string_case("void java.lang.management.MemoryUsage.<init>(long, long, long, long)"):
			string_case("long java.lang.ClassLoader.findNative(java.lang.ClassLoader, java.lang.String)"):
			string_case("void java.lang.NoSuchMethodError.<init>(java.lang.String)"):
			string_case("java.lang.invoke.MethodType java.lang.invoke.MethodHandleNatives.findMethodHandleType(java.lang.Class, java.lang.Class[])"):
			string_case("java.lang.Class java.util.HashMap.comparableClassFor(java.lang.Object)"):
			string_case("java.lang.Class java.lang.ClassLoader.loadClass(java.lang.String)"):
			string_case("void java.lang.ClassCastException.<init>(java.lang.String)"):
			string_case("int java.util.HashMap.compareComparables(java.lang.Class, java.lang.Object, java.lang.Object)"):
			string_case("int java.lang.StringUTF16.hashCode(byte[])"):
			string_case("java.lang.Object java.lang.invoke.Invokers$Holder.linkToCallSite(java.lang.Object, java.lang.Object, java.lang.Object, java.lang.Object)"):
			string_case("int java.lang.StringUTF16.indexOf(byte[], int, int)"):
			string_case("int jdk.internal.util.ArraysSupport.hugeLength(int, int)"):
			string_case("void java.lang.ref.Finalizer.register(java.lang.Object)"):
			string_case("boolean java.util.Collections$EmptyList.equals(java.lang.Object)"):
			string_case("java.lang.Object java.lang.invoke.Invokers$Holder.linkToCallSite(java.lang.Object, java.lang.Object)"):
			string_case("boolean java.lang.Class.desiredAssertionStatus()"):
			string_case("void sun.nio.fs.WindowsException.<init>(int)"):
			string_case("java.lang.Object java.lang.StackStreamFactory$AbstractStackWalker.doStackWalk(long, int, int, int, int)"):
			string_case("java.lang.String java.lang.StringUTF16.newString(byte[], int, int)"):
			string_case("java.util.Calendar java.util.Calendar.createCalendar(java.util.TimeZone, java.util.Locale)"):
			string_case("java.lang.RuntimeException jdk.internal.util.Preconditions.outOfBoundsCheckIndex(java.util.function.BiFunction, int, int)"):
			string_case("java.lang.String net.minecraft.util.text.ITextProperties.getString()"):
				return true;
			default:
#if _BUILD_MSVC
				carbide::dump::compiled_method_check(name);
#endif

				return false;
		}
	}

	static bool always_compile_method(const char * __restrict name) {
		if (_unlikely(!name)) [[unlikely]] {
			name = "<unknown>";
		}

		auto contains = [name](const char * __restrict str) {
			return strstr(name, str) != nullptr;
		};

		for (const char * __restrict str : {
			"org.objectweb.asm",
			"org.lwjgl",
			"net.optifine",
			"com.mojang.blaze3d",
			"net.minecraft.client.renderer",
			"net.minecraft.crash.CrashReport.func",
			"sun.java2d",
			"org.apache.logging",
			"it.unimi.dsi.fastutil",
			"com.google",
			//"net.minecraft.world.IWorldReader.func",
			//"net.minecraft.world.IEntityReader.func",
			//"net.minecraft.world.World.func",
			//"net.minecraft.state.Property.func",
			" net.minecraft.entity",
			//" net.minecraft.world.biome",
			//" net.minecraft.world.lighting",
			" net.minecraft.world",
			" net.minecraft.state",
			"net.minecraft.network",
			" net.minecraft.util",
			" net.minecraft.nbt",
			" net.minecraft.block",
			" net.minecraft.client.multiplayer.ClientChunkProvider",
			" net.minecraft.village.PointOfInterestManager",
			" net.minecraft.client.audio",
			" net.minecraft.client.network",
			" net.minecraftforge",
			" java.util",
			" java.lang",
			" jdk.internal",
			//" java.util.concurrent",
			//" java.lang.invoke",
			//" java.lang.reflect",
			//" java.util.BitSet",
			//" java.util.zip",
			//" java.util.Collections",
			//" java.util.Arrays",
			//" java.lang.ClassLoader",
			//" java.lang.Integer",
			//" java.lang.Float",
			//" java.lang.Double",
			//" java.lang.Math",
			//" java.lang.StrictMath",
			//" java.lang.Thread",
			//" java.lang.Number",
			//" java.lang.StringCoding",
			//" java.util.HashMap",
			//" java.util.LinkedHashMap",
			//" jdk.internal.math",
			" java.net",
			" java.nio",
			//" java.util.stream",
			//" java.util.OptionalInt",
			" com.mojang.serialization",
			" com.mojang.datafixers",
			" sun.reflect.misc",
			" io.netty",
			"hashCode()",
			"toString()",
			"equals(",
			"linkToCallSite",
			"close()",
			"render",
			"Render",
			"CrashReport",
			"valueOf",
			"write(",
			"charAt(",
			"getComparator",
			"checkIndex",
			"add(",
			"allocateDirect",
			"length(",
			"newBytesFor",
			"NumberFormatException",
			"IOException",
			"getName(",
			"newIllegalAccessException",
			" xaero.",
			"net.minecraft.world.chunk",
		}) {
			if (contains(str)) {
				return true;
			}
		}

		string_switch(name) {
			//string_case("void java.lang.Object.<init>()"):
			//string_case("void java.lang.Integer.<init>(int)"):
			//string_case("void java.lang.NullPointerException.<init>()"):
			//string_case("void java.lang.NullPointerException.<init>(java.lang.String)"):
			//string_case("void java.lang.IllegalStateException.<init>()"):
			//string_case("void java.lang.IllegalStateException.<init>(java.lang.String)"):
			//string_case("void java.lang.IllegalArgumentException.<init>()"):
			//string_case("void java.lang.IllegalArgumentException.<init>(java.lang.String)"):
			//string_case("void java.lang.UnsupportedOperationException.<init>()"):
			//string_case("void java.lang.UnsupportedOperationException.<init>(java.lang.String)"):
			//string_case("java.lang.RuntimeException java.lang.invoke.MethodHandleStatics.newIllegalArgumentException(java.lang.String)"):
			//string_case("boolean java.util.AbstractMap.equals(java.lang.Object)"):
			//string_case("java.lang.Object java.lang.ref.Reference.get()"):
			//string_case("void java.lang.ClassLoader.addClass(java.lang.Class)"):
			//string_case("java.lang.invoke.MethodHandle java.lang.invoke.MethodHandleNatives.linkMethodHandleConstant(java.lang.Class, int, java.lang.Class, java.lang.String, java.lang.Object)"):
			//string_case("java.lang.invoke.MemberName java.lang.invoke.MethodHandleNatives.linkCallSite(java.lang.Object, int, java.lang.Object, java.lang.Object, java.lang.Object, java.lang.Object, java.lang.Object[])"):
			//string_case("void java.lang.management.MemoryUsage.<init>(long, long, long, long)"):
			//string_case("long java.lang.ClassLoader.findNative(java.lang.ClassLoader, java.lang.String)"):
			//string_case("void java.lang.NoSuchMethodError.<init>(java.lang.String)"):
			//string_case("java.lang.invoke.MethodType java.lang.invoke.MethodHandleNatives.findMethodHandleType(java.lang.Class, java.lang.Class[])"):
			//string_case("java.lang.Class java.util.HashMap.comparableClassFor(java.lang.Object)"):
			//string_case("java.lang.Class java.lang.ClassLoader.loadClass(java.lang.String)"):
			//string_case("void java.lang.ClassCastException.<init>(java.lang.String)"):
			//string_case("int java.util.HashMap.compareComparables(java.lang.Class, java.lang.Object, java.lang.Object)"):
			//string_case("int java.lang.StringUTF16.hashCode(byte[])"):
			//string_case("java.lang.Object java.lang.invoke.Invokers$Holder.linkToCallSite(java.lang.Object, java.lang.Object, java.lang.Object, java.lang.Object)"):
			//string_case("int java.lang.StringUTF16.indexOf(byte[], int, int)"):
			//string_case("int jdk.internal.util.ArraysSupport.hugeLength(int, int)"):
			//string_case("void java.lang.ref.Finalizer.register(java.lang.Object)"):
			//string_case("boolean java.util.Collections$EmptyList.equals(java.lang.Object)"):
			//string_case("java.lang.Object java.lang.invoke.Invokers$Holder.linkToCallSite(java.lang.Object, java.lang.Object)"):
			//string_case("boolean java.lang.Class.desiredAssertionStatus()"):
			string_case("void sun.nio.fs.WindowsException.<init>(int)"):
			//string_case("java.lang.Object java.lang.StackStreamFactory$AbstractStackWalker.doStackWalk(long, int, int, int, int)"):
			//string_case("java.lang.String java.lang.StringUTF16.newString(byte[], int, int)"):
			//string_case("java.util.Calendar java.util.Calendar.createCalendar(java.util.TimeZone, java.util.Locale)"):
			//string_case("java.lang.RuntimeException jdk.internal.util.Preconditions.outOfBoundsCheckIndex(java.util.function.BiFunction, int, int)"):

			string_case("java.lang.String net.minecraft.util.text.ITextProperties.getString()"):
			//string_case("com.mojang.serialization.MapEncoder com.mojang.serialization.Encoder.fieldOf(java.lang.String)"):
			//string_case("com.mojang.serialization.MapDecoder com.mojang.serialization.Decoder.fieldOf(java.lang.String)"):
				return true;
			default:
#if _BUILD_MSVC
				carbide::dump::compiled_method_check(name);
#endif

				return false;
		}
	}
}
