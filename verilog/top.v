module top;
    logic clk;
    logic[12:0] v;
    // assign v[3:0] = 32'b0;

    test a(.clk);
    test_2 b(.clk);

    always_ff @(posedge clk) begin
    end
endmodule