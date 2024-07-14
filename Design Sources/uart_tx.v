// Module Name: uart_tx
// Date : 2024/03/24
// Version : V0.1
// Author : Maoyang
// Description: Implements a UART transmitter with optional parity bit functionality. This module encodes and transmits 
// data over a serial line using the UART protocol. It supports transmitting data with start, stop, and optional parity bits,
// and signals the completion of transmission.

// Inputs:
// clk: System clock signal for synchronizing the transmission process (Baud Rate).
// ap_rstn: Asynchronous, active low reset signal to initialize or reset the module's internal states.
// ap_ready: Input signal indicating readiness to start data transmission. When high, transmission begins.
// pairty: Input signal to enable (when high) or disable (when low) parity bit generation and transmission.
// data: 8-bit data input to be transmitted over UART.

// Outputs:
// ap_valid: Output signal that indicates the completion of a data transmission cycle.
// tx: Serial output transmitting the encoded data along with start, stop, and optional parity bits.

// Local Parameters:
// FSM_IDLE, FSM_STAR, FSM_TRSF, FSM_PARI, FSM_STOP: Represent the states of the finite state machine (FSM) controlling
// the UART transmission process, from idle, through start bit, data transmission, optional parity bit, and stop bit.

// Internal Registers:
// fsm_statu: Holds the current state of the FSM.
// fsm_next: Determines the next state of the FSM based on the current state and input signals.
// cnter: Counter used during the data transmission state to index through the data bits.

// Behavioral Blocks:
// 1. fsm statu transfer: Sequential logic block that updates the current state of the FSM on each positive clock edge or
//    on negative edge of ap_rstn. Resets to FSM_IDLE on reset.
// 2. fsm conditional transfer: Combinatorial logic block that determines the next state of the FSM based on current 
//    conditions like ap_ready signal, counter value, and parity configuration.
// 3. fsm - output: Sequential logic block that performs actions based on the current FSM state, including setting the
//    tx output according to the data bits, generating a parity bit if enabled, and indicating the end of transmission 
//    through ap_valid signal. Also handles the initialization of internal signals on reset.

// Note: This module is designed to be synthesized and integrated into larger systems requiring UART transmission 
// capabilities, with configurable support for parity bit for error detection.
module uart_tx(
    input   clk,
    input   ap_rstn,
    input   ap_ready,
    output  reg ap_valid,
    output  reg tx,
    input   pairty,
    input  [7:0] data
);

localparam  FSM_IDLE = 3'b000,
            FSM_STAR = 3'b001,
            FSM_TRSF = 3'b010,
            FSM_PARI = 3'b011,
            FSM_STOP = 3'b100;

reg [2:0] fsm_statu;
reg [2:0] fsm_next;
reg [2:0] cnter;

//fsm statu transfer;
always @(posedge clk, negedge ap_rstn) begin
    if (!ap_rstn)begin
        fsm_statu <= FSM_IDLE;
    end else begin
        fsm_statu <= fsm_next;
    end
end

//fsm conditional transfer;
always @(*)begin
    if(!ap_rstn)begin
        fsm_next <= FSM_IDLE;
    end else begin
        case(fsm_statu)
            FSM_IDLE:begin 
                fsm_next <= (ap_ready) ? FSM_STAR : FSM_IDLE;
            end
            FSM_STAR: fsm_next <= FSM_TRSF;
            FSM_TRSF:begin 
                fsm_next <= (cnter == 3'h7) ? (pairty?FSM_PARI:FSM_STOP) : FSM_TRSF;
            end
            FSM_PARI: fsm_next <= FSM_STOP;
            FSM_STOP:begin 
                fsm_next <= (!ap_ready) ? FSM_IDLE : FSM_STOP;
            end
            default: fsm_next <= FSM_IDLE;
        endcase
    end
end

//fsm - output
always @(posedge clk, negedge ap_rstn)begin
    if(!ap_rstn)begin
        ap_valid <= 1'b0;
        tx <= 1'b1;
        cnter <= 3'h0;
    end else begin
        case (fsm_statu)
            FSM_IDLE: begin 
                tx <= 1'b1;
                ap_valid <= 1'b0;
            end
            FSM_STAR: begin 
                tx <= 1'b0;
                cnter <= 3'h0;
            end
            FSM_TRSF: begin
                tx <= data[cnter];
                cnter <= cnter + 1'b1;
            end
            FSM_PARI: tx <= (^data); //Parity Check - ODD Check;
            FSM_STOP: begin
                tx <= 1'b1;         //Stop Bit;
                ap_valid <= 1'b1;
            end
        endcase
    end
end

endmodule