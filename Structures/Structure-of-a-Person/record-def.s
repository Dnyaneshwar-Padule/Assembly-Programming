.equ RECORD_FIRSTNAME, 0    # length of first name is 40 bytes
.equ RECORD_LASTNAME, 40    # length of last name is 40 byes
.equ RECORD_ADDRESS, 80     # length of address is 240
.equ RECORD_AGE, 320        # age is a number, a single byte is sufficient for it, but we are taking it's size a word long, for better processing

.equ RECORD_SIZE, 324       # Total size of the structure
