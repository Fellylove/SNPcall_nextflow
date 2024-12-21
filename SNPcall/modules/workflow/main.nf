#!/usr/bin/env nextflow

// INCLUDES # here you must give the relevant processes from the modules/process directory 
include {samtools_merge;Picard_MarkDuplicates;Freebayes;bcftools;bamQC} from "${projectDir}/modules/process"

// SUB-WORKFLOWS
workflow 'SNPcall' {

    // take the initial Channels and paths
    take:
        BAMS
        fasta
        fai

    // here we define the structure of our workflow i.e. how the different processes lead into each other
    // eg. process(input1, input2, etc.)
    // eg. process.out[0], process.out[1], etc.
    // index numbers [0],[1],etc. refer to different outputs defined for processes in process.nf
    // ALWAYS PAY ATTENTION TO CARDINALITY!!
    main:

	// we should use the collect operator to get all BAM files into a single item emitted by the Channel
    samtools_merge(BAMS.collect())

	// Picard MarkDuplicates only ever takes the output Channel from samtools_merge
	Picard_MarkDuplicates(samtools_merge.out)

	// Freebayes and bamQC run differently depending on whether or not we use --markDups
	if(params.markDups){
	    Freebayes(Picard_MarkDuplicates.out[0],fasta,fai)
	    bamQC(Picard_MarkDuplicates.out[0])
	} else {
	    Freebayes(samtools_merge.out,fasta,fai)
	    bamQC(samtools_merge.out)
	}

	// bcftools filtering only ever runs on the output from Freebayes
	bcftools(Freebayes.out)
}