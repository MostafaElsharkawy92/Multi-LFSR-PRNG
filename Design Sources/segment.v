`timescale 1ns / 1ps

module segment(
    input rstn,
    input clk500hz,
    input [15:0] bcd_num,
    output [3:0] an,
    output [7:0] segment
);

reg [7:0] segment_r;
reg [3:0] an_r;
assign segment = ~ segment_r;
reg [3:0] cur_num_r;        //Register - BCD Number Display at this moment; 
assign an = ~an_r;

//Drive 7Segment Anode;
//When an_r == 0001, DIG4 will turn on;
//When an_r == 0001, at posedge clk500hz, an_r will be set to 0010(DIG3 ON);
//When an_r == 0010, at posedge clk500hz, an_r will be set to 0100(DIG2 ON);
//....
//DIG4 -> DIG3 -> DIG2 -> DIG1 -> DIG4 -> DIG3 -> DIG2 -> ...;
always @(negedge rstn,posedge clk500hz)begin
    if(!rstn)begin
        an_r <= 4'b0000;    //When system reset, empty all display;
    end
    else begin
        case(an_r)                  
        4'b0001: an_r <= 4'b0010;   //DISPLAY ON DIG3
        4'b0010: an_r <= 4'b0100;   //DISPLAY ON DIG2
        4'b0100: an_r <= 4'b1000;   //DISPLAY ON DIG1
        default: an_r <= 4'b0001;   //DISPLAY ON DIG4
        endcase
    end
end

//When DIG4 on, BCD Number Display at this moment is bcd_num[3:0];  (i.e Stop Watch - Second Unit)
//When DIG3 on, BCD Number Display at this moment is bcd_num[7:4];  (i.e Stop Watch - Second Decade)
//When DIG2 on, BCD Number Display at this moment is bcd_num[11:8]; (i.e Stop Watch - Minute Unit)
//When DIG1 on, BCD Number Display at this moment is bcd_num[15:12];(i.e Stop Watch - Minute Decade)
always @(an_r,bcd_num)begin
    case(an_r)
        4'b0001: cur_num_r <= bcd_num[3:0];
        4'b0010: cur_num_r <= bcd_num[7:4];
        4'b0100: cur_num_r <= bcd_num[11:8];
        4'b1000: cur_num_r <= bcd_num[15:12];
        default: cur_num_r <= 4'b0;
    endcase    
end

//Decode BCD NUM into corrosponding 7Segment Code;
always @(cur_num_r) begin
    case(cur_num_r)
        4'h0:segment_r <= 8'hc0;    //NUM "0"
        4'h1:segment_r <= 8'hf9;    //NUM "1"
        4'h2:segment_r <= 8'ha4;    //NUM "2"
        4'h3:segment_r <= 8'hb0;    //NUM "3"
        4'h4:segment_r <= 8'h99;    //NUM "4"
        4'h5:segment_r <= 8'h92;    //NUM "5"
        4'h6:segment_r <= 8'h82;    //NUM "6"
        4'h7:segment_r <= 8'hF8;    //NUM "7"
        4'h8:segment_r <= 8'h80;    //NUM "8"
        4'h9:segment_r <= 8'h90;    //NUM "9"
        4'hA:segment_r <= 8'h88; //NUM "A"
        4'hB:segment_r <= 8'h83; //NUM "b"
        4'hC:segment_r <= 8'hc6; //NUM "C"
        4'hD:segment_r <= 8'ha1; //NUM "d"
        4'hE:segment_r <= 8'h86; //NUM "E"
        4'hF:segment_r <= 8'h8e; //NUM "F"
        default: segment_r <= 8'hff;
    endcase
end

endmodule
