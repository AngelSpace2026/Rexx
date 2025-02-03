/* REXX Program: Angel_1.0.0.0.rex */
PARSE SOURCE . . script_name .
IF script_name \= 'Angel_1.0.0.0.rex' THEN DO
    SAY "This is not 'Angel_1.0.0.0.rex'."
    EXIT
END
SAY "The script 'Angel_1.0.0.0.rex' is currently running."

/* Program Header */
SAY "Created by Jurijus Pacalovas. Advanced Binary Compressor v1.0.0.0"

/* Global Variables */
CIRCLE_TIMES = 0
ROW = 0
EN_NUMBER = 28
FILE_INFO = ''

/* Main Compression Flow */
CALL COMPRESSION_ROUTINE

EXIT

/*---------------------------------*/
/* Main Compression Routine        */
/*---------------------------------*/
COMPRESSION_ROUTINE:
PROCEDURE EXPOSE CIRCLE_TIMES ROW EN_NUMBER FILE_INFO

/* Get file details */
SAY "What is the name of the input file?"
PARSE PULL name

/* File extension check */
IF SUBSTR(REVERSE(name),1,2) == 'b.' THEN DO
    i = 2
    CALL EXTRACTION_PROCESS
END
ELSE DO
    i = 1
    DO FOREVER
        SAY "Enter intersection points (2-28):"
        PARSE PULL EN_NUMBER
        IF DATATYPE(EN_NUMBER,'W') THEN DO
            EN_NUMBER = TRUNC(EN_NUMBER)
            IF EN_NUMBER >= 2 & EN_NUMBER <= 28 THEN LEAVE
        END
        SAY "Invalid input. Please enter 2-28."
    END
END

/* File existence check */
IF STREAM(name, 'C', 'QUERY EXISTS') = '' THEN DO
    SAY "File does not exist!"
    EXIT
END

/* Read and process binary data */
bin_data = CHARIN(name, 1, 1000000)  /* Read 1MB max */
hex_data = C2X(bin_data)
info = X2B(hex_data) || COPIES('0', (LENGTH(hex_data)//2)*8)
start_time = TIME('E')

/* Main compression logic */
DO WHILE CIRCLE_TIMES < 10
    FILE_INFO = PROCESS_BLOCKS(info, EN_NUMBER)
    info = FILE_INFO
    CIRCLE_TIMES = CIRCLE_TIMES + 1
END

/* Write output */
compressed_hex = B2X(FILE_INFO)
compressed_bin = X2C(compressed_hex)
output_name = name || '.b'

CALL CHAROUT output_name, compressed_bin
elapsed = TIME('E') - start_time
SAY "Compression completed in" elapsed "seconds"
RETURN

/*---------------------------------*/
/* Block Processing Function       */
/*---------------------------------*/
PROCESS_BLOCKS: PROCEDURE EXPOSE ROW
PARSE ARG info, en_num

compressed = ''
block_size = en_num
DO WHILE LENGTH(info) > 0
    /* Dynamic block sizing */
    current_block = LEFT(info, block_size)
    info = SUBSTR(info, block_size + 1)
    
    /* Pattern detection and encoding */
    SELECT
        WHEN POS('00000000', current_block) > 0 THEN
            compressed = compressed || '0' || D2C(block_size) || current_block
        WHEN POS('11111111', current_block) > 0 THEN
            compressed = compressed || '1' || D2C(block_size) || current_block
        OTHERWISE
            compressed = compressed || current_block
    END
    
    /* Dynamic EN adjustment */
    ROW = MIN(ROW + 1, (2**28) - 1)
    block_size = MIN(block_size + 1, 2**28 - 1)
END

RETURN compressed

/*---------------------------------*/
/* Extraction Process              */
/*---------------------------------*/
EXTRACTION_PROCESS:
PROCEDURE EXPOSE FILE_INFO
PARSE ARG name

SAY "Starting extraction process..."
extracted_data = ''
i = 1

DO WHILE i <= LENGTH(FILE_INFO)
    /* Read control byte */
    control_byte = SUBSTR(FILE_INFO, i, 1)
    block_size = C2D(SUBSTR(FILE_INFO, i+1, 1))
    i = i + 2
    
    /* Process block based on control byte */
    SELECT
        WHEN control_byte == '0' THEN
            extracted_data = extracted_data || COPIES('00000000', block_size)
        WHEN control_byte == '1' THEN
            extracted_data = extracted_data || COPIES('11111111', block_size)
        OTHERWISE
            extracted_data = extracted_data || SUBSTR(FILE_INFO, i, block_size)
    END
    i = i + block_size
END

/* Write extracted file */
output_name = SUBSTR(name, 1, LENGTH(name)-2)
hex_data = B2X(extracted_data)
CALL CHAROUT output_name, X2C(hex_data)
RETURN

/*---------------------------------*/
/* Binary/Hex Conversion Functions */
/*---------------------------------*/
X2B: PROCEDURE /* Hex to Binary */
PARSE ARG hex
hex_chars = '0123456789ABCDEF'
bin = ''
DO i = 1 TO LENGTH(hex)
    c = SUBSTR(hex,i,1)
    n = POS(c, hex_chars) - 1
    bin = bin || RIGHT(D2B(n),4,0)
END
RETURN bin

B2X: PROCEDURE /* Binary to Hex */
PARSE ARG bin
hex = ''
DO i = 1 TO LENGTH(bin) BY 4
    chunk = SUBSTR(bin,i,4)
    hex = hex || D2C(B2D(chunk))
END
RETURN hex

B2D: PROCEDURE /* Binary to Decimal */
PARSE ARG bin
dec = 0
DO i = 1 TO LENGTH(bin)
    dec = dec * 2 + SUBSTR(bin,i,1)
END
RETURN dec

D2B: PROCEDURE /* Decimal to Binary */
PARSE ARG dec
IF dec = 0 THEN RETURN '0000'
bin = ''
DO WHILE dec > 0
    bin = (dec // 2) || bin
    dec = dec % 2
END
RETURN RIGHT(bin,4,0)