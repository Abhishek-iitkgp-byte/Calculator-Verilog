module calculator_tb;

parameter N = 16;

reg clk;
reg reset;
reg start;
reg [N-1:0] A;
reg [N-1:0] B;
reg [2:0] opcode;

wire [2*N-1:0] Y;
wire done;
wire signed [2*N-1:0] Y_signed;

assign Y_signed = Y;

integer file;
integer r;
reg [7:0] op;

localparam ADD = 3'b000;
localparam SUB = 3'b001;
localparam MUL = 3'b010;
localparam DIV = 3'b011;
localparam GCD = 3'b100;

Calculator #(N) uut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .A(A),
    .B(B),
    .opcode(opcode),
    .Y(Y),
    .done(done)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    reset = 1;
    start = 0;
    #20;
    reset = 0;

    file = $fopen("input.txt","r");

    if(file == 0) begin
        $display("Cannot open input.txt");
        $finish;
    end

    while(!$feof(file)) begin

        r = $fscanf(file,"%d %c %d\n", A, op, B);

        case(op)
            "+": opcode = ADD;
            "-": opcode = SUB;
            "*": opcode = MUL;
            "/": opcode = DIV;
            "G": opcode = GCD;
        endcase

        start = 1;
        #10;
        start = 0;

        if(op == "G")
            wait(done == 1);

        #10;

        if(op == "-")
            $display("%0d %s %0d = %0d", A, op, B, Y_signed);
        else
            $display("%0d %s %0d = %0d", A, op, B, Y[N-1:0]);
    end

    $fclose(file);
    $finish;
end

endmodule
