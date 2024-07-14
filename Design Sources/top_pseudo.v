module pseudo_top(
    input btnRst,
    input sysclk,
    output [3:0] an,
    output [7:0] segment,
    input vp_in,
    input vn_in,
    input [1:0] xa_n,
    input [1:0] xa_p,
    output uart_rxd_out    
);

// Reset signal
wire rstn;
assign rstn = ~btnRst; // Active-low reset

// XADC declarations
localparam PIN15_ADDR = 8'h14; // VAUX4
localparam PIN16_ADDR = 8'h1C; // VAUX12
wire enable;                   // Enable signal for continuous XADC data output
reg [6:0] Address_in = 7'h14;  // Address of register in XADC DRP corresponding to data
wire ready;                    // XADC port indicating data readiness
wire [15:0] ADC_data;          // XADC data   

// Registers and wires to hold the generated number
wire [15:0] gen_number;
reg [15:0] sampled_number;
reg [15:0] display_number;

// Clock signals
wire clk_uart, clk_tx_event, clk_data_proc, clk_16x, clk_500Hz, clk_7seg;

// Instantiations
generator int1(
    .clk(clk_16x),
    .rst(btnRst),
    .seed(ADC_data),
    .random_number(gen_number)
);

segment s0(
    .rstn(rstn),
    .clk500hz(clk_500Hz),
    .bcd_num(display_number),
    .an(an),
    .segment(segment)
);

// Frequency of random number generation
localparam gen_frequency = 50_000;

// Clock divider instances
clock_div clock_div_u0(
    .clkout(clk_uart),
    .rstn(rstn),
    .clksrc(sysclk)
);

defparam clock_div_u0.FREQ_INPUT = 12_000_000; // Input frequency to the clock divider
defparam clock_div_u0.FREQ_OUTPUT = 1152000;    // Output frequency for UART operations

clock_div clock_div_u1(
    .clkout(clk_tx_event),
    .rstn(rstn),
    .clksrc(sysclk)
);
defparam clock_div_u1.FREQ_INPUT = 12_000_000; // Input frequency
defparam clock_div_u1.FREQ_OUTPUT = gen_frequency * 2;     // Output frequency for TX event timing

clock_div clock_div_u2(
    .clkout(clk_data_proc),
    .rstn(rstn),
    .clksrc(sysclk)
);
defparam clock_div_u2.FREQ_INPUT = 12_000_000; // Input frequency
defparam clock_div_u2.FREQ_OUTPUT = gen_frequency;      // Output frequency for data processing

clock_div clock_div_u3(
    .clkout(clk_16x),
    .rstn(rstn),
    .clksrc(sysclk)
);
defparam clock_div_u3.FREQ_INPUT = 12_000_000; // Input frequency
defparam clock_div_u3.FREQ_OUTPUT = gen_frequency * 16;    // 16x above

clock_div clock_div_u4(
    .clkout(clk_500Hz),
    .rstn(rstn),
    .clksrc(sysclk)
);
defparam clock_div_u4.FREQ_INPUT = 12_000_000; // Input frequency to the clock divider
defparam clock_div_u4.FREQ_OUTPUT = 500;       // Output frequency for 7-segment display refresh

clock_div clock_div_u5(
    .clkout(clk_7seg),
    .rstn(rstn),
    .clksrc(sysclk)
);
defparam clock_div_u5.FREQ_INPUT = 12_000_000; // Input frequency to the clock divider
defparam clock_div_u5.FREQ_OUTPUT = 1;         // Output frequency for 7-segment display change

// UART protocol instance for transmitting data with parameter configuration for parity
localparam UART_PARITY = 1'b0; // Parity configuration, 0 for even parity
reg uart_tx_ready;
wire uart_tx_valid;
reg [7:0] uart_tx_data;

uart_tx uart_tx_u0(
    .clk(clk_uart),
    .ap_rstn(rstn),
    .ap_ready(uart_tx_ready),
    .ap_valid(uart_tx_valid),
    .tx(uart_rxd_out),
    .pairty(UART_PARITY),
    .data(uart_tx_data)
);

// XADC instance
xadc_wiz_0 xadc_u0(
    .daddr_in(PIN16_ADDR), // Address bus for the dynamic reconfiguration port
    .dclk_in(sysclk),      // Clock input for the dynamic reconfiguration port
    .den_in(enable),       // Enable signal for the dynamic reconfiguration port
    .di_in(0),             // Input data bus for the dynamic reconfiguration port
    .dwe_in(0),            // Write enable for the dynamic reconfiguration port
    .vauxp12(xa_p[1]),
    .vauxn12(xa_n[1]),
    .vauxp4(xa_p[0]),
    .vauxn4(xa_n[0]),  
    .busy_out(),           // ADC busy signal
    .channel_out(),        // Channel selection outputs
    .do_out(ADC_data),     // Output data bus for dynamic reconfiguration port
    .drdy_out(ready),      // Data ready signal for the dynamic reconfiguration port
    .eoc_out(enable),      // End of conversion signal
    .vp_in(vp_in),         // Dedicated analog input pair
    .vn_in(vn_in)
);

// Sample every generated number for UART
always @(posedge clk_tx_event) begin
    sampled_number <= gen_number;
end

// Sample generated number at a lower frequency for reading on 7-segment display
always @(posedge clk_7seg) begin
    display_number <= gen_number; 
end

// 16-bit auto-incrementing counter for transmitting data to a PC
reg [15:0] cnter;
reg odd;
always @(negedge rstn or posedge clk_data_proc) begin
    if (!rstn) begin
        cnter <= 8'h00;
        uart_tx_data <= 8'h00;
        odd <= 1'b0;
    end else begin
        odd <= ~odd;
        uart_tx_data <= odd ? sampled_number[15:8] : sampled_number[7:0];
        // You can replace cnter with your random number generator, e.g., a 16-bit wire [15:0] rng_number
        // cnter <= odd ? rng_number : ; // Allow you to transmit number to PC
    end
end

// Control logic for UART transmission readiness based on TX event clock and reset signal
always @(posedge clk_tx_event or negedge rstn) begin
    if (!rstn) begin
        uart_tx_ready <= 1'b0;
    end else begin
        if (uart_tx_valid) begin
            uart_tx_ready <= 1'b0;
        end else begin
            uart_tx_ready <= 1'b1;
        end
    end
end

endmodule
