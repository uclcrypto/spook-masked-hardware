from spook_hw_api import utils_prng_spook

def ext_bit(b_str,idx):
    # Byte in which to extract
    b_idx = int(idx/8)
    offset = idx % 8

    # Extraction
    mask = 2**offset
    b_ext = (b_str[b_idx] & mask) >> offset
    return b_ext

def lfsr_stage(S):
    # Randomness generation
    #Sb99 = ext_bit(S,98)
    #Sb101 = ext_bit(S,100)
    #Sb126 = ext_bit(S,125)
    #Sb128 = ext_bit(S,127)
    #
    #SbXNOR = not(Sb99 ^ Sb101 ^ Sb126 ^ Sb128)
    
    A = S[15]
    B = S[12]

    A = A ^ (B<<3)
    A = A ^ (A<<2)

    SbXNOR = not(A & 0b10000000)

    # Update state
    Sbint = int.from_bytes(S,'little')
    shift_Sbint = ((Sbint << 1) ^ SbXNOR) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    S[:] = shift_Sbint.to_bytes(16,'little')[:]

def lfsr_rnd_bits(S,am):
    # Generated randomness
    rnd_int = 0

    # Advance with LFSR state
    for i in range(int(am)):
        lfsr_stage(S)
        bit_rnd = S[0] & 0b1
        rnd_int = rnd_int + (2**i)*bit_rnd

    # Compute the amount of bytes required to represent the data
    bytes_am = int(am/8)
    if (am % 8)!=0:
        bytes_am = bytes_am+1

    # Return the randomness as a list of bytes
    rnd_bytes = rnd_int.to_bytes(bytes_am,'little')
    return list(rnd_bytes)

