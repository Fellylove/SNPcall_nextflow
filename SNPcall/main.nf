#!/usr/bin/env nextflow

// PRINT HELP AND EXIT
if(params.help){
    include { printHelp } from './lib/functions.nf'
    printHelp()
}

// PRINT VERSION AND EXIT
if(params.version){
    include { printVersion } from './lib/functions.nf'
    printVersion()
}

// DEFINE PATHS # these are strings which are used to define input Channels,
// but they are specified here as they may be referenced in LOGGING
fasta = file("${params.reference}", checkIfExists: true, glob: false)
fai = file("${params.reference}.fai", checkIfExists: true, glob: false)
bam_path = "${params.input}/*.bam"


// PRINT STANDARD LOGGING INFO
include { printLogging } from './lib/functions.nf'
printLogging()



////////////////////
// STAGE CHANNELS //
////////////////////

/*
 *   Channels are where you define the input for the different
 *    processes which make up a pipeline. Channels indicate
 *    the flow of data, i.e. the "route" that a file will take.
 */

// STAGE BAM FILES FROM TEST PROFILE # this establishes the test data to use with -profile test
if ( workflow.profile.tokenize(",").contains("test") ){

        include { check_test_data } from './lib/functions.nf' params(bamPaths: params.bamPaths)
        BAMS = check_test_data(params.bamPaths)

} else {

    // STAGE READS CHANNELS # this defines the normal input when test profile is not in use
    BAMS = Channel
        .fromPath(bam_path)
        .ifEmpty{ exit 1, """Cannot find valid read files in dir: ${params.input}
        The pipeline will expect BAM files in *.bam format"""}
        .take(params.take.toInteger())

}



////////////////////
// BEGIN PIPELINE //
////////////////////

/*
 *   Workflows are where you define how different processes link together. They
 *    may be modularised into "sub-workflows" which must be named eg. 'DNAseq'
 *    and there must always be one MAIN workflow to link them together, which
 *    is always unnamed.
 */

include { SNPcall } from "${projectDir}/modules/workflow"

// MAIN WORKFLOW 
workflow {

    // call sub-workflows eg. WORKFLOW(Channel1, Channel2, Channel3, etc.)
    main:
        SNPcall(BAMS, fasta, fai)

}


//////////////////
// END PIPELINE //
//////////////////

// WORKFLOW TRACING # what to display when the pipeline finishes
// eg. with errors
workflow.onError {
    log.info "Oops... Pipeline execution stopped with the following message: ${workflow.errorMessage}"
}

// eg. in general
include { printSummary } from './lib/functions.nf'
workflow.onComplete {

    printSummary()

    // run a small clean-up script to remove "work" directory after successful completion 
    if (!params.debug && workflow.success) {
        ["bash", "${baseDir}/bin/clean.sh", "${workflow.sessionId}"].execute() }
}
