from spook_hw_api import utils_api
from spook_hw_api import spook_api_builder

# Return the bytes representation of a value represented as a hex string.
def fh(x):
    return bytes.fromhex(x)

# Parse the NIST tv file 's'.
def dec_tv_file(s):
    return [
            (d['Key'], d['Nonce'], d['PT'], d['AD'], d['CT'])
            for d in (dict((k, fh(v))
                for k, _, v in (y.split(' ') for y in x.split('\n')) if k != 'Count')
                for x in s.strip().split('\n\n'))
            ]

# Write the cases set in the file with name 'fname'
def write_tv_file(fname,cases,bus_size=4):
    f = open(fname,'w+')
    for i,case in enumerate(cases):
        [csize,cbytes,_] = case
        f.write("%d=ID"%(i+1))
        f.write("\n")
        for j in range(csize):
            f.write(cbytes[j*bus_size:j*bus_size+bus_size].hex())
            f.write("\n")
        f.write("--------\n")
    f.write("########\n")
    f.close()


# Build the file used for the HW testbench
# The ref. tv file is 'fname'.
# The generated file is '$prefix$_$mode$_tv.txt', where prefix can be 'None' (not taken)
# Three mode are possible:
#    1) 'enc': generate the commands for encryption only
#    2) 'dec': generate the commands for decryption only
#    3) 'glob': generate the commands for encryption and decryption.
def build_hw_tv_files(outdir='.',fname='LWC_AEAD_KAT_128_128.txt',suffix=None,mode='enc',SEG_MAX_CMDS=8,L_ENDIAN=False,DSHARE=2,seeds=None):
    # Create the builder 
    builder = spook_api_builder.Spook_API_Builder(L_ENDIAN=L_ENDIAN,DSHARE=DSHARE,SEG_MAX_CMDS=SEG_MAX_CMDS)

    # Decode NIST file
    tv = dec_tv_file(open(fname).read())
    ltv = len(tv)

    lcs = ltv
    if mode=='glob':
        lcs = 2*lcs

    # Create case commands set 
    cases = lcs*[0]
    cases_res = lcs*[0]

    # Create command 
    for i,case in enumerate(tv):
        # Seed generation
        s0 = None
        s1 = None
        s2 = None
        if DSHARE>1:
            if seeds==None:
                s0 = bytes(utils_api.rand_bytes_vec(16)) 
                s1 = bytes(utils_api.rand_bytes_vec(16)) 
                s2 = bytes(utils_api.rand_bytes_vec(16))
            else:
                assert len(seeds)==3, 'Error in the format of the seeds provided'
                s0 = seeds[0]
                s1 = seeds[1]
                s2 = seeds[2]

        # Proceed to commands generation
        if ((mode == 'enc') | (mode == 'glob')):
            cases[i] = builder.build_encrypt(case[3],case[2],case[1],s0=s0,s1=s1,s2=s2,k=case[0])  
            cases_res[i] = builder.build_res_encrypt(case[4],s0=s0,s1=s1,s2=s2,k=case[0])
        elif mode == 'dec':
            cases[i] = builder.build_decrypt(case[3],case[4],case[1],s0=s0,s1=s1,s2=s2,k=case[0])
            cases_res[i] = builder.build_res_decrypt(case[2],s0=s0,s1=s1,s2=s2,k=case[0])
        if mode == 'glob':
            cases[i+ltv] = builder.build_decrypt(case[3],case[4],case[1],s0=s0,s1=s1,s2=s2,k=case[0])
            cases_res[i+ltv] = builder.build_res_decrypt(case[2],s0=s0,s1=s1,s2=s2,k=case[0])
    # Write name
    fn_suffix = mode
    if suffix!=None:
        fn_suffix = suffix + '_' + fn_suffix

    fname = outdir+'/' + 'tv_' + fn_suffix + '.txt'
    fname_res = outdir+'/' + 'tv_' + fn_suffix + '_res.txt'
    write_tv_file(fname,cases,bus_size=4)
    write_tv_file(fname_res,cases_res,bus_size=4)

