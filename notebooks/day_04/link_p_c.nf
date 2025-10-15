#!/usr/bin/env nextflow

process SPLITLETTERS {
    tag "$out_str"

    input:
    tuple val(in_str), val(block_size), val(out_str)

    output:
    path "${out_str}_block_*", emit: blocks

    script:
    """
    #!/usr/bin/env python
    import pandas as pd

    in_str = "$in_str"
    block_size = int("$block_size")
    out_str = "$out_str"

    blocks = [in_str[i:i+block_size] for i in range(0, len(in_str), block_size)]
    df = pd.DataFrame({'block_index': range(len(blocks)), 'chunk': blocks})

    for _, row in df.iterrows():
        with open(f"{out_str}_block_{row['block_index']}.txt", "w") as f:
            f.write(row['chunk'])
    """
}


process CONVERTTOUPPER {
     tag "$file.name"

    publishDir "results", mode: 'copy'

    input:
    path file

    output:
    path "${file.baseName}_upper.txt"
    stdout emit: upper_text  

    script:
    """
    #!/usr/bin/env python
    with open("${file}", "r") as f:
        text = f.read().upper()

    # write the uppercase file
    with open(f"${file.baseName}_upper.txt", "w") as out:
        out.write(text)

    # also print text for channel
    print(text)
    """
}


workflow {
    // 1. Read in the samplesheet (samplesheet_2.csv)  into a channel. The block_size will be the meta-map
    // 2. Create a process that splits the "in_str" into sizes with size block_size. The output will be a file for each block, named with the prefix as seen in the samplesheet_2
    // 4. Feed these files into a process that converts the strings to uppercase. The resulting strings should be written to stdout


    // Step one: Create the results files - I don't think I did this as intended, hope that is fine
    if (params.step == 1) {
        
    // Read samplesheet
    in_ch = Channel
        .fromPath('samplesheet_2.csv')
        .splitCsv(header: true)
        .map { row ->
            def in_str = row.input_str
            def block_size = row.block_size
            def out_str = row.out_name
            return [in_str, block_size, out_str]
        }

    // Split strings
    split_blocks = SPLITLETTERS(in_ch)

    // Flatten
    flat_blocks = split_blocks.blocks.flatten()

  
    // convert the chunks to uppercase and save the files to the results directory
    converted = CONVERTTOUPPER(flat_blocks)
    converted.upper_text.view { txt -> "Uppercase:\n$txt" }
    }

    // Step 2: Return a list of filenames
    if(params.step == 2){

    results_ch = Channel
                .fromPath('results/*.txt')
                .filter { it.name.endsWith('_upper.txt') }
                .collect()     

    results = results_ch.view()

    }
}




