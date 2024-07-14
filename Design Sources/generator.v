`timescale 1ns / 1ps

module generator(
    input clk,                
    input rst,                
    input [15:0] seed,        
    output reg [15:0] random_number 
);

// Internal signals
wire feedback;
reg [15:0] lfsr;  
reg [3:0] bit_count;  

// Taps
assign feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
assign feedback2 = lfsr[7] ^ lfsr[3] ^ lfsr[2] ^ lfsr[1];
assign feedback3 = lfsr[6] ^ lfsr[0];
assign feedback4 = lfsr[5] ^ lfsr[0];

// LFSR; bit accumulation logic
always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        lfsr <= seed;           // Initialize the LFSR with a non-zero value
        bit_count <= 0;          // Reset the bit counter
        random_number <= 0;           // Reset the 16-bit random number
    end 
    
    else 
    begin
        lfsr <= {lfsr[14:0], feedback + feedback2 + feedback3 + feedback4};  // Shift and insert feedback
        if (bit_count < 16) 
        begin
            // Shift in the last bit of the LFSR into the rand_num register
            random_number[bit_count] <= lfsr[0];
            bit_count <= bit_count + 1;
        end 
        
        else 
        begin
            // Reset the bit counter to start generating the next random number
            bit_count <= 0;
        end
    end
end

endmodule