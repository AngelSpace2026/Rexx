/* REXX Program: Angel_1.0.0.0.rex */
/* Ensure the script is running with the correct name */
PARSE SOURCE . . script_name .
IF script_name \= 'Angel_1.0.0.0.rex' THEN DO
    SAY "This is not 'Angel_1.0.0.0.rex'."
    EXIT
END
SAY "The script 'Angel_1.0.0.0.rex' is currently running."

/* Program Header */
SAY "Created by Jurijus Pacalovas. Welcome to the Binary Data Compressor and Extractor! Angel_1.0.0.0"

/* Ask user for input and output file names */
PARSE UPPER VAR user_input "Enter input file name: " input_file
PARSE UPPER VAR user_input "Enter output file name: " output_file

/* Ask user for operation (1 = Compress, 2 = Extract) */
PARSE UPPER VAR user_input "Enter operation (1 = Compress, 2 = Extract): " operation

/* Validate operation input */
IF operation \= 1 & operation \= 2 THEN DO
    SAY "Invalid operation. Please enter 1 for Compress or 2 for Extract."
    EXIT
END

/* Read input file */
IF STREAM(input_file, 'C', 'QUERY EXISTS') == '' THEN DO
    SAY "Input file does not exist."
    EXIT
END
input_data = CHARIN(input_file, 1, 1000000) /* Read up to 1MB of data */

/* Perform compression or extraction */
IF operation == 1 THEN DO
    SAY "Compressing data..."
    compressed_data = COMPRESS(input_data)
    CALL CHAROUT output_file, compressed_data
    SAY "Data compressed and saved to" output_file
END
ELSE IF operation == 2 THEN DO
    SAY "Extracting data..."
    extracted_data = EXTRACT(input_data)
    CALL CHAROUT output_file, extracted_data
    SAY "Data extracted and saved to" output_file
END

EXIT

/* Compression Function */
COMPRESS: PROCEDURE
    ARG data
    compressed_data = ""
    count = 1
    DO i = 2 TO LENGTH(data)
        IF SUBSTR(data, i, 1) == SUBSTR(data, i - 1, 1) THEN
            count = count + 1
        ELSE DO
            compressed_data = compressed_data || D2C(count) || SUBSTR(data, i - 1, 1)
            count = 1
        END
    END
    compressed_data = compressed_data || D2C(count) || SUBSTR(data, LENGTH(data), 1)
    RETURN compressed_data

/* Extraction Function */
EXTRACT: PROCEDURE
    ARG data
    extracted_data = ""
    i = 1
    DO WHILE i <= LENGTH(data)
        count = C2D(SUBSTR(data, i, 1))
        char = SUBSTR(data, i + 1, 1)
        extracted_data = extracted_data || COPIES(char, count)
        i = i + 2
    END
    RETURN extracted_data