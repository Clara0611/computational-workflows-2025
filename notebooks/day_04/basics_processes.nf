params.step = 0
params.zip = 'zip'


process SAYHELLO {
    debug true
    script:
        """
        echo "Hello World!"
        """
}

process SAYHELLO_PYTHON {
    debug true
    script:
    """
    #!/usr/bin/env python

    print("Hello world")
    """

    //or: python -c print("Hello world")"
}

 process SAYHELLO_PARAM {
        debug true   // print output to console

        input:
        val greeting_ch   // take the value from the channel

        script:
        """
        echo "${greeting_ch}"
        """
    }

    process SAYHELLO_FILE {
        debug true   // print output to console

        // Input: directly take value from the channel
        input:
        val greeting_ch

        // Output: write to a file
        output:
        path "greeting.txt"   // the file produced by the process

        script:
        """
        echo "${greeting_ch}" > greeting.txt
        """
    }

       process UPPERCASE {
        debug true

        input: val greeting_ch

        output: path "uppercase.txt"

        script:
        """
        echo "${greeting_ch}".toUpperCase > uppercase.txt
        """
       }

    // Process to read the file and print contents
    process PRINTUPPER {
        debug true

        input:
        path file_in

        script:
        """
        cat ${file_in}
        """
    }

      process ZIPFILE {
        debug true

        input:
        path file_in

        output:
        path "*.zip", emit: zipped_file  

        script:
        """
        if [ "${params.zip}" = "zip" ]; then
            zip uppercase.zip ${file_in}
        elif [ "${params.zip}" = "gzip" ]; then
            gzip -c ${file_in} > uppercase.txt.gz
        elif [ "${params.zip}" = "bzip2" ]; then
            bzip2 -c ${file_in} > uppercase.txt.bz2
        else
            echo "Unknown zip format: ${params.zip}" >&2
            exit 1
        fi
        """
    }

        process ZIPALL {
        debug true

        input:
        path file_in

        output:
        path "*.zip"
        path "*.gz"
        path "*.bz2"

        script:
        """
        # ZIP
        zip uppercase.zip ${file_in}

        # GZIP
        gzip -c ${file_in} > uppercase.txt.gz

        # BZIP2
        bzip2 -c ${file_in} > uppercase.txt.bz2
        """
    }

     
    process WRITETOFILE {
        debug true

        input:
        val rows  

        output:
        path "results/names.tsv"

        script:
        """
        mkdir -p results
        # write header
        echo -e "name\\ttitle" > results/names.tsv
        # write each row
        ${rows.collect { "echo -e '${it.name}\\t${it.title}' >> results/names.tsv" }.join('\n')}
        """
    }


workflow {

    // Task 1 - create a process that says Hello World! (add debug true to the process right after initializing to be sable to print the output to the console)
    if (params.step == 1) {
        SAYHELLO()
    }

    // Task 2 - create a process that says Hello World! using Python
    if (params.step == 2) {
        SAYHELLO_PYTHON()
    }

    // Task 3 - create a process that reads in the string "Hello world!" from a channel and write it to command line
    if (params.step == 3) {
        greeting_ch = Channel.of("Hello world!")
        SAYHELLO_PARAM(greeting_ch)
    }

    // Task 4 - create a process that reads in the string "Hello world!" from a channel and write it to a file. WHERE CAN YOU FIND THE FILE?
    if (params.step == 4) {
        greeting_ch = Channel.of("Hello world!")
        SAYHELLO_FILE(greeting_ch)
        //It stores it in nextflows work directory
    }

    // Task 5 - create a process that reads in a string and converts it to uppercase and saves it to a file as output. View the path to the file in the console
    if (params.step == 5) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)
        out_ch.view()
        //Result: File created at: /home/clara/computational-workflows-2025/notebooks/day_04/work/ac/31b7711ac28ff8d59b308ee219c7af/uppercase.txt
    }

    // Task 6 - add another process that reads in the resulting file from UPPERCASE and print the content to the console (debug true). WHAT CHANGED IN THE OUTPUT?
    if (params.step == 6) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)
        PRINTUPPER(out_ch)
    }

    
    // Task 7 - based on the paramater "zip" (see at the head of the file), create a process that zips the file created in the UPPERCASE process either in "zip", "gzip" OR "bzip2" format.
    //          Print out the path to the zipped file in the console
    if (params.step == 7) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)
        ZIPFILE(out_ch).view()
    }

    // Task 8 - Create a process that zips the file created in the UPPERCASE process in "zip", "gzip" AND "bzip2" format. Print out the paths to the zipped files in the console

    if (params.step == 8) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)
        out_ch_zipped = ZIPALL(out_ch)
        out_ch_zipped.mix().view()
    }

    // Task 9 - Create a process that reads in a list of names and titles from a channel and writes them to a file.
    //          Store the file in the "results" directory under the name "names.tsv"

    if (params.step == 9) {
        in_ch = channel.of(
            ['name': 'Harry', 'title': 'student'],
            ['name': 'Ron', 'title': 'student'],
            ['name': 'Hermione', 'title': 'student'],
            ['name': 'Albus', 'title': 'headmaster'],
            ['name': 'Snape', 'title': 'teacher'],
            ['name': 'Hagrid', 'title': 'groundkeeper'],
            ['name': 'Dobby', 'title': 'hero'],
        )
        
    in_ch.toList() | WRITETOFILE
    }

}