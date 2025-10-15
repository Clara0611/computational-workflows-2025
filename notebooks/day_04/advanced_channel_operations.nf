params.step = 0

    process READ_SAMPLESHEET {
        debug true

        input: path file_in

        script:
        """
         #!/usr/bin/env python
        import pandas as pd

        df = pd.read_csv("${file_in}")
        print(df.head())
        """
    }

workflow{

    // Task 1 - Read in the samplesheet. RUNS TWICE!!!

    if (params.step == 1) {
        in_ch = channel.fromPath('samplesheet.csv')
        READ_SAMPLESHEET(in_ch)
    
    }

    // Task 2 - Read in the samplesheet and create a meta-map with all metadata and another list with the filenames ([[metadata_1 : metadata_1, ...], [fastq_1, fastq_2]]).
    //          Set the output to a new channel "in_ch" and view the channel. YOU WILL NEED TO COPY AND PASTE THIS CODE INTO SOME OF THE FOLLOWING TASKS (sorry for that).

    if (params.step == 2) {
        in_ch = Channel
            .fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .map { row ->
                def meta = row.findAll { k, v -> !(k in ['fastq_1', 'fastq_2']) }
                def reads = [ file(row.fastq_1), file(row.fastq_2) ]
                return [meta, reads]}
        in_ch.view()
    }

    // Task 3 - Now we assume that we want to handle different "strandedness" values differently. 
    //          Split the channel into the right amount of channels and write them all to stdout so that we can understand which is which.

    if (params.step == 3) {
        in_ch = Channel
            .fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .map { row ->
                def meta = row.findAll { k, v -> !(k in ['fastq_1', 'fastq_2']) }
                def reads = [ file(row.fastq_1), file(row.fastq_2) ]
                return [meta, reads]}

        grouped = in_ch.map{meta, reads -> tuple(meta.strandedness, meta.sample, reads)}.groupTuple(by:0)
        grouped.view{strand, metas, reads_list -> 
            "Strandedness=${strand} | meta=${metas} | reads=${reads_list}"}
    }

    // Task 4 - Group together all files with the same sample-id and strandedness value.

    if (params.step == 4) {

         in_ch = Channel
            .fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .map { row ->
                def meta = row.findAll { k, v -> !(k in ['fastq_1', 'fastq_2']) }
                def reads = [ file(row.fastq_1), file(row.fastq_2) ]
                return [meta, reads]}

        grouped = in_ch.map{meta, reads -> tuple(meta.strandedness, meta.sample, reads)}.groupTuple(by:[0,1])
        grouped.view{strand, metas, reads_list -> 
            "Strandedness=${strand} | meta=${metas} | reads=${reads_list}"}
        

    }



}