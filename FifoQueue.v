`timescale 1ns / 1ps
module FifoQueue #(
    parameter ENTRY_NUMBER = 16,
    parameter ENTRY_WIDTH = 4,
    parameter DATA_WIDTH = 32

) (
      input clk,
      input rst,
      input read,
      input write,
      input [DATA_WIDTH-1:0] fifo_in,
      output reg [DATA_WIDTH-1:0] fifo_out,
      output fifo_empty,
      output fifo_full
);

    reg [DATA_WIDTH-1  : 0] ram [ENTRY_NUMBER-1:0];
    reg [ENTRY_WIDTH-1 : 0] read_ptr, write_ptr, counter;

    always @ (posedge clk) begin
        if(rst) begin
            read_ptr  <= 0;
            write_ptr <= 0;
            counter   <= 0;
            fifo_out  <= {DATA_WIDTH{1'b0}};
        end else begin
            case ({read, write})
                2'b00: counter <= counter;
                2'b01: begin
                    ram[write_ptr] <= fifo_in;
                    counter        <= counter + 1;
                    write_ptr      <= write_ptr + 1;
                end
                2'b10: begin
                    if (counter) begin
                        counter  <= counter - 1;
                        read_ptr <= read_ptr + 1;
                    end
                end
                2'b11: begin
                    if (counter == 0)
                        read_ptr <= read_ptr;
                    else begin
                        ram[write_ptr] <= fifo_in;
                        write_ptr      <= write_ptr + 1;
                        read_ptr       <= read_ptr + 1;
                    end
                end
            endcase
        end
    end
    always @ (*) begin
        if (counter == 0) begin
            if (write)
                fifo_out <= fifo_in;
            else
                fifo_out <= {DATA_WIDTH{1'b0}};
        end else
            fifo_out <= ram[read_ptr];
    end

    assign fifo_empty = (counter == 0) && (write == 0);
    assign fifo_full = (counter == ENTRY_NUMBER) && (read == 0);
endmodule
