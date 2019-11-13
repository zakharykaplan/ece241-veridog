//
//  draw.v
//  Draw an image from ROM
//
//  Created by Zakhary Kaplan on 2019-11-12.
//  Copyright © 2019 Zakhary Kaplan. All rights reserved.
//

module draw160x120(
    input resetn,
    input clk,
    input start,

    output [7:0] xOut,
    output [6:0] yOut,
    output [7:0] colour,
    output writeEn,
    output done
    );

    parameter IMAGE = "./assets/black.mif";

    // Iterator
    wire [7:0] x;
    wire [6:0] y;
    iterator #(8, 7, 160, 120) ITERATOR(
        .resetn(resetn),
        .clk(clk),
        .start(start),
        .xInit(8'b0),
        .yInit(7'b0),
        .x(x),
        .y(y),
        .writeEn(writeEn),
        .done(done)
    );

    // Image memory rom for retrieving colour
    rom160x120 ROM(
        .address((160 * y) + x),
        .clock(CLOCK_50),
        .q(colour));
    defparam ROM.altsyncram_component.init_file = IMAGE;
endmodule


module draw40x40(
    input resetn,
    input clk,
    input start,
    input [5:0] xInit,
    input [5:0] yInit,

    output [5:0] xOut,
    output [5:0] yOut,
    output [7:0] colour,
    output writeEn,
    output done
    );

    parameter IMAGE = "./assets/black.mif";

    // Iterator
    wire [5:0] x;
    wire [5:0] y;
    iterator #(6, 6, 40, 40) ITERATOR(
        .resetn(resetn),
        .clk(clk),
        .start(start),
        .xInit(xInit),
        .yInit(yInit),
        .x(x),
        .y(y),
        .writeEn(writeEn),
        .done(done)
    );

    // Image memory rom for retrieving colour
    rom160x120 ROM(
        .address((40 * y) + x),
        .clock(CLOCK_50),
        .q(colour));
    defparam ROM.altsyncram_component.init_file = IMAGE;
endmodule


module iterator #(
    parameter   X_WIDTH = 8,
                Y_WIDTH = 7,
                X_MAX = 160,
                Y_MAX = 120) (

    input resetn,
    input clk,
    input start,

    output reg [X_WIDTH-1:0] x,
    output reg [Y_WIDTH-1:0] y,
    output reg writeEn,
    output reg done
    );


    // State registers
    reg [1:0] currentState, nextState;

    localparam  IDLE    = 2'h0,
                LOAD    = 2'h1,
                WRITE   = 2'h2,
                DONE    = 2'h3;


    // Drawing state table
    always @(*)
    begin: stateTable
        case (currentState)
            IDLE: nextState = (start) ? LOAD: IDLE;
            LOAD: nextState = WRITE;
            WRITE: nextState = (~done) ? LOAD : DONE;
            DONE: nextState = (start) ? DONE : IDLE;
            default: nextState = IDLE;
        endcase
    end // stateTable


    // Perform state functions
    always @(*)
    begin: stateFunctions
        case (currentState)
            LOAD: begin
                x = x + {{X_WIDTH-1{1'b0}}, 1'b1};
                if (x == X_MAX) begin
                    x = {X_WIDTH{1'b0}};
                    y = y + {{Y_WIDTH-1{1'b0}}, 1'b1};

                    if (y == Y_MAX) begin
                        done = 1'b1;
                    end
                end
            end
            WRITE: writeEn = 1'b1;
            DONE: done = 1'b1;
            default: begin
                x = {X_WIDTH{1'b0}};
                y = {Y_WIDTH{1'b0}};
                writeEn = 1'b0;
                done = 1'b0;
            end
        endcase
    end // stateFunctions


    // Update state registers
    always @(posedge clk)
    begin: stateFFs
        if (!resetn)
            currentState <= IDLE;
        else
            currentState <= nextState;
    end // stateFFs
endmodule
