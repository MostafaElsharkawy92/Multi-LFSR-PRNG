Hardware Implementation of Multi-LFSR Pseudo Random Number Generator

# T04-new
This is an implementation of a hardware pseudo-random number generator using LFSR for generation, and ambient electromagnetic noise for seed generation.

16-bit random numbers are generated at a frequency of 50kHz. Clicking the reset button grabs a new seed. There is also a UART connection with a baud rate of 1152000 to transfer the generated numbers.

## Design
The FPGA system consists of 3 modules: 
- Clock divider (clk_div.v)
- LFSR generator (generator.v)
- 7 Segment display (segment.v)
- UART TX (uart_tx.v)
- XADC (Vivado IP)

### Pseudorandom generator

We are using the Linear Feedback Shift Register to generate pseudo-random numbers. It is a sequential shift register with feedback that is linear in nature. It consists of a series of flip-flops connected in a chain. The output of certain flip-flops is fed back to the input through an Exclusive-OR function. The feedback path determines the characteristics of the LFSR, including its maximum sequence length and the  patterns of bits it generates.

To attain better randomness at 16-bit length, we implemented 4 LFSRs to generate each number. Each LSFR using a different XOR combination of bits from the LFSR, thus they tap into different positions within the LFSR, creating diverse patterns of feedback. In the always block,  instead of simply shifting in one feedback bit, the four feedback signals are added together. This combines the influences of the different feedback polynomials, resulting in a more complex and less predictable sequence of bits generated.

### Seed generation

The seed is obtained from electromagnetic noise from the environment. An ADC reads the value from a rudimentary antenna, to be used as the seed. Since electromagnetic noise in the environment is random, the seed generation is robust for pseudo-random number generation. Even though the noise level is quite low, approximately 8 bits (out of 12 bits ADC) is useful, with the upper 4 bits being 0s. This is sufficient to be the seed for generation with multiple LFSRs.

### Testbench
A testbench was also written to test the randomness of the generated numbers. On each generation of a new random number by the generator module, the testbench writes the number to a text file. After storing enough numbers for testing, the textfile is parsed by our Python code for histogram generation to analyse if the generated numbers are random enough. This testbench allowed us to rapidly test different combintions of LFSRs with different feedback polynomials to determine which combination of feedback polynomials gives us the most random set of numbers. 



## Challenges

1) ADC output is small, as electrical noise value is small. Better randomness is achieved with multiple LFSRs.

2) Needed to rewrite the code for the clock due to the use of the Linear Feedback Shift Register. Had to set a 16Hz clock cycle because we could only use the last bit of the 16x outputs of the LFSR to generate a truly random number every second. 

3) Difficult to implement methods of transforming the initial data that follows a uniform distribution to data that follows a gaussian distribution within a limited time using methods such as the Box Muller transform in Verilog. Thus, we did this data conversion using the Scipy and Numpy Python libraries instead. 

4) We faced challenges with UART when changing the baud rate from 9600 to 115200. This was made to speed up the generation of 1 million random numbers as it would typically take about 30 minutes to generate such a large amount of pseudo-random number, but by speeding it up, it only took a few minutes to generate a million pseudo-random numbers. We were able to increase the baud rate to 1152000, generating and receiving 1 million numbers in 40s.

## Data analysis
The raw hexadecimal random numbers were then sent from the FPGA to the computer via a UART and subsequently stored in an array. The array was used to plot a histogram showing the number distribution. Taking 1 million values, the max value we get is 65535.000000 while our mean is 32766.275753 which is half. 
