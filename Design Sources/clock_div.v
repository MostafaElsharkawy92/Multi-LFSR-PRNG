//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.03.2024 15:41:25
// Design Name: 
// Module Name: clock_div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clock_div(
    input rstn,
    input clksrc,
    output clkout
);

parameter FREQ_INPUT  = 12_000_000;
parameter FREQ_OUTPUT = 1_000;
parameter CNTER_MAX = FREQ_INPUT/(FREQ_OUTPUT*2);
parameter CNTER_WIDTH = $clog2(CNTER_MAX);

reg clkout_r;
reg [CNTER_WIDTH-1:0] cnter;
assign clkout = clkout_r;

always @(negedge rstn,posedge clksrc) begin
    if(!rstn)begin
        cnter <= {CNTER_WIDTH{1'b0}};
        clkout_r <= 1'b0;
    end
    else begin
        if(cnter == CNTER_MAX - 1'b1)begin
            clkout_r <= ~clkout_r;
            cnter <= {CNTER_WIDTH{1'b0}};            
        end
        else begin
            cnter <= cnter + 1'b1;
        end
    end    
end

endmodule
