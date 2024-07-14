`timescale 1ns / 1ps

module generator_tb();
    reg clk, rst;
    reg [15:0] seed;
    wire [15:0] random_number;
    

generator u1(clk, rst, seed, random_number);


integer fp;
reg [15:0] prev_random_number;

initial begin
    fp = $fopen("prng7.txt", "a");
    #1
    $fclose(fp);

    #1
    fp = $fopen("prng7.txt", "a");
    prev_random_number = 0; // Initialize with a dummy value
    #100000000; // Wait for some time to allow random numbers to be generated
    $fclose(fp);
    $finish;
    
    
end

initial begin
    #5
    seed <= 16'd10325;
    clk <= 1'b0;
    rst <= 1'b0;
    #5
    rst <= 1'b1;
    #5
    rst <= 1'b0;
end

always begin
#5 clk = !clk;
end


always @(random_number) begin
//    if (random_number !== prev_random_number) begin // Check if the random number has changed
        $fwrite(fp, "\n", random_number);
//        prev_random_number = random_number; // Update the previous value
//    end
end

    
endmodule
