/*
 * Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.
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


package org.graalvm.compiler.hotspot.replacements;

import static org.graalvm.compiler.hotspot.GraalHotSpotVMConfigBase.INJECTED_METAACCESS;
import static org.graalvm.compiler.hotspot.GraalHotSpotVMConfigBase.INJECTED_VMCONFIG;

import org.graalvm.compiler.core.common.CompressEncoding;
import org.graalvm.compiler.core.common.spi.ForeignCallDescriptor;
import org.graalvm.compiler.debug.DebugHandlersFactory;
import org.graalvm.compiler.hotspot.GraalHotSpotVMConfig;
import org.graalvm.compiler.hotspot.meta.HotSpotForeignCallsProviderImpl;
import org.graalvm.compiler.hotspot.meta.HotSpotProviders;
import org.graalvm.compiler.hotspot.meta.HotSpotRegistersProvider;
import org.graalvm.compiler.hotspot.nodes.GraalHotSpotVMConfigNode;
import org.graalvm.compiler.hotspot.nodes.HotSpotCompressionNode;
import org.graalvm.compiler.nodes.ValueNode;
import org.graalvm.compiler.nodes.gc.ShenandoahArrayRangePostWriteBarrier;
import org.graalvm.compiler.nodes.gc.ShenandoahArrayRangePreWriteBarrier;
import org.graalvm.compiler.nodes.gc.ShenandoahPostWriteBarrier;
import org.graalvm.compiler.nodes.gc.ShenandoahPreWriteBarrier;
import org.graalvm.compiler.nodes.gc.ShenandoahReferentFieldReadBarrier;
import org.graalvm.compiler.nodes.spi.LoweringTool;
import org.graalvm.compiler.options.OptionValues;
import org.graalvm.compiler.replacements.ReplacementsUtil;
import org.graalvm.compiler.replacements.SnippetCounter.Group;
import org.graalvm.compiler.replacements.SnippetCounter.Group.Factory;
import org.graalvm.compiler.replacements.SnippetTemplate.AbstractTemplates;
import org.graalvm.compiler.replacements.SnippetTemplate.SnippetInfo;
import org.graalvm.compiler.replacements.gc.ShenandoahWriteBarrierSnippets;
import org.graalvm.compiler.word.Word;
import jdk.internal.vm.compiler.word.WordFactory;

import jdk.vm.ci.code.Register;
import jdk.vm.ci.code.TargetDescription;
import jdk.vm.ci.meta.JavaKind;
import jdk.vm.ci.meta.ResolvedJavaType;

public final class HotSpotShenandoahWriteBarrierSnippets extends ShenandoahWriteBarrierSnippets {
    public static final ForeignCallDescriptor SHENANDOAHWBPRECALL = new ForeignCallDescriptor("write_barrier_pre", void.class, Object.class);
    public static final ForeignCallDescriptor SHENANDOAHWBPOSTCALL = new ForeignCallDescriptor("write_barrier_post", void.class, Word.class);
    public static final ForeignCallDescriptor VALIDATE_OBJECT = new ForeignCallDescriptor("validate_object", boolean.class, Word.class, Word.class);

    private final GraalHotSpotVMConfig config;
    private final Register threadRegister;

    public HotSpotShenandoahWriteBarrierSnippets(GraalHotSpotVMConfig config, HotSpotRegistersProvider registers) {
        this.config = config;
        this.threadRegister = registers.getThreadRegister();
    }

    @Override
    protected Word getThread() {
        return HotSpotReplacementsUtil.registerAsWord(threadRegister);
    }

    @Override
    protected int wordSize() {
        return HotSpotReplacementsUtil.wordSize();
    }

    @Override
    protected int objectArrayIndexScale() {
        return ReplacementsUtil.arrayIndexScale(INJECTED_METAACCESS, JavaKind.Object);
    }

    @Override
    protected int satbQueueMarkingOffset() {
        return HotSpotReplacementsUtil.shenandoahSATBQueueMarkingOffset(INJECTED_VMCONFIG);
    }

    @Override
    protected int satbQueueBufferOffset() {
        return HotSpotReplacementsUtil.shenandoahSATBQueueBufferOffset(INJECTED_VMCONFIG);
    }

    @Override
    protected int satbQueueIndexOffset() {
        return HotSpotReplacementsUtil.shenandoahSATBQueueIndexOffset(INJECTED_VMCONFIG);
    }

    @Override
    protected byte dirtyCardValue() {
        return HotSpotReplacementsUtil.dirtyCardValue(INJECTED_VMCONFIG);
    }

    @Override
    protected Word cardTableAddress() {
        return WordFactory.unsigned(GraalHotSpotVMConfigNode.cardTableAddress());
    }

    @Override
    protected int cardTableShift() {
        return HotSpotReplacementsUtil.cardTableShift(INJECTED_VMCONFIG);
    }

    @Override
    protected int logOfHeapRegionGrainBytes() {
        return GraalHotSpotVMConfigNode.logOfHeapRegionGrainBytes();
    }

    @Override
    protected ForeignCallDescriptor preWriteBarrierCallDescriptor() {
        return SHENANDOAHWBPRECALL;
    }

    @Override
    protected ForeignCallDescriptor postWriteBarrierCallDescriptor() {
        return SHENANDOAHWBPOSTCALL;
    }

    @Override
    protected boolean verifyOops() {
        return HotSpotReplacementsUtil.verifyOops(INJECTED_VMCONFIG);
    }

    @Override
    protected boolean verifyBarrier() {
        return ReplacementsUtil.REPLACEMENTS_ASSERTIONS_ENABLED || config.verifyBeforeGC || config.verifyAfterGC;
    }

    @Override
    protected long gcTotalCollectionsAddress() {
        return HotSpotReplacementsUtil.gcTotalCollectionsAddress(INJECTED_VMCONFIG);
    }

    @Override
    protected ForeignCallDescriptor verifyOopCallDescriptor() {
        return HotSpotForeignCallsProviderImpl.VERIFY_OOP;
    }

    @Override
    protected ForeignCallDescriptor validateObjectCallDescriptor() {
        return VALIDATE_OBJECT;
    }

    @Override
    protected ForeignCallDescriptor printfCallDescriptor() {
        return Log.LOG_PRINTF;
    }

    @Override
    protected ResolvedJavaType referenceType() {
        return HotSpotReplacementsUtil.referenceType(INJECTED_METAACCESS);
    }

    @Override
    protected long referentOffset() {
        return HotSpotReplacementsUtil.referentOffset(INJECTED_METAACCESS);
    }

    public static class Templates extends AbstractTemplates {
        private final SnippetInfo shenandoahPreWriteBarrier;
        private final SnippetInfo shenandoahReferentReadBarrier;
        private final SnippetInfo shenandoahPostWriteBarrier;
        private final SnippetInfo shenandoahArrayRangePreWriteBarrier;
        private final SnippetInfo shenandoahArrayRangePostWriteBarrier;

        private final ShenandoahWriteBarrierLowerer lowerer;

        public Templates(OptionValues options, Iterable<DebugHandlersFactory> factories, Group.Factory factory, HotSpotProviders providers, TargetDescription target, GraalHotSpotVMConfig config) {
            super(options, factories, providers, providers.getSnippetReflection(), target);
            this.lowerer = new HotspotShenandoahWriteBarrierLowerer(config, factory);

            HotSpotShenandoahWriteBarrierSnippets receiver = new HotSpotShenandoahWriteBarrierSnippets(config, providers.getRegisters());
            shenandoahPreWriteBarrier = snippet(ShenandoahWriteBarrierSnippets.class, "shenandoahPreWriteBarrier", null, receiver, GC_INDEX_LOCATION, GC_LOG_LOCATION, SATB_QUEUE_MARKING_LOCATION, SATB_QUEUE_INDEX_LOCATION,
                            SATB_QUEUE_BUFFER_LOCATION);
                            shenandoahReferentReadBarrier = snippet(ShenandoahWriteBarrierSnippets.class, "shenandoahReferentReadBarrier", null, receiver, GC_INDEX_LOCATION, GC_LOG_LOCATION, SATB_QUEUE_MARKING_LOCATION,
                            SATB_QUEUE_INDEX_LOCATION,
                            SATB_QUEUE_BUFFER_LOCATION);
                            shenandoahPostWriteBarrier = snippet(ShenandoahWriteBarrierSnippets.class, "shenandoahPostWriteBarrier", null, receiver, GC_CARD_LOCATION, GC_INDEX_LOCATION, GC_LOG_LOCATION, CARD_QUEUE_INDEX_LOCATION,
                            CARD_QUEUE_BUFFER_LOCATION);
                            shenandoahArrayRangePreWriteBarrier = snippet(ShenandoahWriteBarrierSnippets.class, "shenandoahArrayRangePreWriteBarrier", null, receiver, GC_INDEX_LOCATION, GC_LOG_LOCATION, SATB_QUEUE_MARKING_LOCATION,
                            SATB_QUEUE_INDEX_LOCATION, SATB_QUEUE_BUFFER_LOCATION);
                            shenandoahArrayRangePostWriteBarrier = snippet(ShenandoahWriteBarrierSnippets.class, "shenandoahArrayRangePostWriteBarrier", null, receiver, GC_CARD_LOCATION, GC_INDEX_LOCATION, GC_LOG_LOCATION,
                            CARD_QUEUE_INDEX_LOCATION, CARD_QUEUE_BUFFER_LOCATION);
        }

        public void lower(ShenandoahPreWriteBarrier barrier, LoweringTool tool) {
            lowerer.lower(this, shenandoahPreWriteBarrier, barrier, tool);
        }

        public void lower(ShenandoahReferentFieldReadBarrier barrier, LoweringTool tool) {
            lowerer.lower(this, shenandoahReferentReadBarrier, barrier, tool);
        }

        public void lower(ShenandoahPostWriteBarrier barrier, LoweringTool tool) {
            lowerer.lower(this, shenandoahPostWriteBarrier, barrier, tool);
        }

        public void lower(ShenandoahArrayRangePreWriteBarrier barrier, LoweringTool tool) {
            lowerer.lower(this, shenandoahArrayRangePreWriteBarrier, barrier, tool);
        }

        public void lower(ShenandoahArrayRangePostWriteBarrier barrier, LoweringTool tool) {
            lowerer.lower(this, shenandoahArrayRangePostWriteBarrier, barrier, tool);
        }
    }

    static final class HotspotShenandoahWriteBarrierLowerer extends ShenandoahWriteBarrierLowerer {
        private final CompressEncoding oopEncoding;

        HotspotShenandoahWriteBarrierLowerer(GraalHotSpotVMConfig config, Factory factory) {
            super(factory);
            oopEncoding = config.useCompressedOops ? config.getOopEncoding() : null;
        }

        @Override
        public ValueNode uncompress(ValueNode expected) {
            assert oopEncoding != null;
            return HotSpotCompressionNode.uncompress(expected, oopEncoding);
        }
    }
}
