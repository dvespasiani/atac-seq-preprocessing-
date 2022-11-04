import os
import itertools
import glob

##===================##
##   config params   ##
##===================##
configfile: "config/snakemake-config.yaml"

species = config['species']
assembly = config['assembly']

basedir = config['basedir']
fastqdir = config['fastqdir']

adapters = config['adapters']
read_length = config['read_length']
genome_size = config['genome_size']
genome_index = config['genome_index']
blacklist = config['blacklist']
chrom_sizes = config['chrom_sizes']
genome2bit_index = config['genome2bit_index']
sample = config['samples']
all_samples = config['all_samples']
combined_sample = list(itertools.chain(*config['combined_sample'])) ## this flattens a list of lists

##=================##
## I/O directories ##
##=================##
outdir = config['outdir']
qcdir = config['qcdir']
logs = config['logs']
plots = config['plots']
tables = config['tables']

##=================##
##   Parameters    ##
##=================##
read_minQ = config['read_minQ']
npeaks = config['npeaks']
fragment_size = config['fragment_size']
shift = config['shift']
pval_thresh = config['pval_thresh']

##=================##
##     RULES       ##
##=================##
main = 'main'
qc = 'qc'

rulename_fastqc = config['fastqc'] +'/'
rulename_trim = config['trim-adapter'] +'/'
rulename_align = config['align'] +'/'
rulename_postalign = config['post-alignment'] +'/'
rulename_peak = config['peak-calling'] +'/'
rulename_deeptools = config['deeptools'] +'/'
rulename_conspeak = config['consensus-peak']

include: "rules/fastqc.smk"
include: "rules/trim-adapter.smk"
include: "rules/alignment.smk"
include: "rules/post-alignment.smk"
include: "rules/peak-calling.smk"
include: "rules/deeptools.smk"
include: "rules/qcs.smk"
include: "rules/consensus-peak.smk"

rule all:
      input:  
            ## fastqc
            expand(fastqdir + "{sample}_R1_001.fastq.gz",sample=sample),
            expand(fastqdir + "{sample}_R2_001.fastq.gz",sample=sample),
            expand(outdir + rulename_fastqc + "{sample}_R1_001_fastqc.zip", sample=sample),
            expand(outdir + rulename_fastqc + "{sample}_R2_001_fastqc.zip", sample=sample),
            
            ## trim-adapter
            expand(outdir + rulename_trim + "{sample}-1-trimmed.fastq.gz",sample=sample),
            expand(outdir + rulename_trim + "{sample}-2-trimmed.fastq.gz",sample=sample),
            expand(outdir + rulename_trim + "{sample}-1-unpaired.fastq.gz", sample=sample),
            expand(outdir + rulename_trim + "{sample}-2-unpaired.fastq.gz", sample=sample),
            
            ## alignment
            expand(outdir + rulename_align + "{sample}.bam",sample=sample),

            ## post-alignment
            expand(outdir + rulename_postalign + "{sample}-nochrM.bam",sample=sample),
            expand(outdir + rulename_postalign + "{sample}-nochrM-encodefiltered.bam",sample=sample),
            expand(outdir + rulename_postalign + "{sample}-nochrM-encodefiltered-fixmate.bam",sample=sample),
            expand(outdir + rulename_postalign + "{sample}-nochrM-encodefiltered-fixmate-rmorphanread.bam",sample=sample),
            expand(outdir + rulename_postalign + "{sample}-nochrM-encodefiltered-fixmate-rmorphanread-dupmark.bam",sample=sample),
            expand(qcdir + "{sample}-duplicate-rate.qc",sample=sample),
            expand(outdir + rulename_postalign + "{sample}-nochrM-encodefiltered-fixmate-rmorphanread-nodup.bam",sample=sample),
            expand(outdir + rulename_postalign + "{sample}-nochrM-encodefiltered-fixmate-rmorphanread-nodup.bai",sample=sample),
            expand(outdir + rulename_postalign + "{sample}-tn5-shifted.bam",sample=sample),
            expand(outdir + rulename_postalign + "{all_samples}-tn5-shifted.bam",all_samples = all_samples),
            expand(outdir + rulename_postalign + "{combined_sample}-tn5-shifted-sorted.bam",combined_sample = combined_sample),
            expand(outdir + rulename_postalign + "{combined_sample}-tn5-shifted-sorted.bam.bai",combined_sample = combined_sample),

            ## peak calling
            expand(outdir + rulename_peak + "{combined_sample}-macs2_peaks.xls",combined_sample=combined_sample),
            expand(outdir + rulename_peak + "{combined_sample}-macs2_treat_pileup.bdg",combined_sample=combined_sample),
            expand(outdir + rulename_peak + "{combined_sample}-macs2_summits.bed",combined_sample=combined_sample),
            expand(outdir + rulename_peak + "{combined_sample}-macs2_control_lambda.bdg",combined_sample=combined_sample),
            expand(outdir + rulename_peak + "{combined_sample}-macs2_peaks.narrowPeak",combined_sample=combined_sample),
            expand(outdir + rulename_peak + "{combined_sample}-macs2-peaks-filtered.narrowPeak.gz",combined_sample=combined_sample),
            expand(outdir + rulename_peak + "{combined_sample}-macs2-peaks-filtered-sorted.narrowPeak.gz",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-macs2_FE.bdg",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-fe-signal.bedgraph",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-fe-signal-sorted.bedgraph",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-fe-signal.bigwig",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-ppois-sval",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-macs2_ppois.bdg",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-ppois-signal.bedgraph",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-ppois-signal-sorted.bedgraph",combined_sample=combined_sample),
            # expand(outdir + rulename_peak + "{combined_sample}-ppois-signal.bigwig",combined_sample=combined_sample),
            expand(qcdir + "{combined_sample}-frip.txt",combined_sample=combined_sample),

            
            ## deeptools
            expand(outdir + rulename_deeptools + "{sample}-noblacklist.bam",sample=sample),
            expand(outdir + rulename_deeptools + "{sample}-noblacklist.bai",sample=sample),
            expand(outdir + rulename_deeptools + "{sample}-SeqDepthNorm.bw",sample=sample),
            outdir  + rulename_deeptools + "samples-bam-coverage.png",
            outdir + rulename_deeptools + "samples-plot-fingerprint.png",
            outdir + rulename_deeptools + "multiBAM-fingerprint-metrics.txt",
            outdir + rulename_deeptools + "multiBAM-fingerprint-rawcounts.txt",
            expand(outdir + rulename_deeptools + "{sample}-GC-content.txt",sample=sample),
            expand(outdir + rulename_deeptools + "{sample}-plot-GC-content.png",sample=sample),
            outdir + rulename_deeptools + "multibam-summary.npz",
            outdir + rulename_deeptools + "multibam-readcounts.txt",
            outdir + rulename_deeptools + "pearson-corr-multibam.png",
            outdir + rulename_deeptools + "pearson-corr-multibamsum-matrix.txt",

            ## qcs
            tables + 'number-reads-bam-files.txt',
            tables + 'number-peaks.txt',
            tables + "library-complexity.txt",
            plots + "bowtie2-alignment-qc.pdf",
            plots + 'frip-summary-qc.pdf',
            plots + 'extra-peak-qcs.pdf',
            plots + 'tss-enrichment.pdf',
            plots + 'support-consensus-peak.pdf',
