module adder4(
    output [3:0] S,
    output cout,
    input [3:0] A,
    input [3:0] B,
    input cin
);

    wire p0,p1,p2,p3;
    wire g0,g1,g2,g3;
    wire c1,c2,c3;

    assign p0 = A[0]^B[0];
    assign p1 = A[1]^B[1];
    assign p2 = A[2]^B[2];
    assign p3 = A[3]^B[3];

    assign g0 = A[0]&B[0];
    assign g1 = A[1]&B[1];
    assign g2 = A[2]&B[2];
    assign g3 = A[3]&B[3];

    assign c1 = g0 | (p0 & cin);
    assign c2 = g1 | (p1 & g0) | (p1 & p0 & cin);
    assign c3 = g2 | (p2 & g1) | (p2 & p1 & g0) | (p2 & p1 & p0 & cin);

    assign cout = g3 | (p3 & g2) | (p3 & p2 & g1) |
                  (p3 & p2 & p1 & g0) |
                  (p3 & p2 & p1 & p0 & cin);

    assign S[0] = p0 ^ cin;
    assign S[1] = p1 ^ c1;
    assign S[2] = p2 ^ c2;
    assign S[3] = p3 ^ c3;

endmodule


// ADD / SUB


module AddSub #(parameter N=16)(
    input [N-1:0] A,
    input [N-1:0] B,
    input mode,                  // 0 add, 1 subtract
    output [N:0] Y
);

wire [N-1:0] B_mod;
wire [(N/4):0] carry_chain;

assign carry_chain[0] = mode;
assign B_mod = B ^ {N{mode}};

genvar i;
generate
    for(i=0; i<N/4; i=i+1) begin : adder_blocks
        adder4 block (
            .A(A[i*4 + 3 : i*4]),
            .B(B_mod[i*4 + 3 : i*4]),
            .cin(carry_chain[i]),
            .S(Y[i*4 + 3 : i*4]),
            .cout(carry_chain[i+1])
        );
    end
endgenerate

assign Y[N] = carry_chain[N/4];

endmodule


// BOOTH MULTIPLIER


module Booths_algo #(parameter N=16)(
    input [N-1:0] a,
    input [N-1:0] b,
    output reg [2*N-1:0] y
);

integer i;
reg [N-1:0] A;
reg [N-1:0] Q;
reg [N-1:0] M;
reg Q_1;
reg [1:0] check;

always @(*) begin
    A   = 0;
    Q   = a;
    M   = b;
    Q_1 = 0;

    for(i=0; i<N; i=i+1) begin
        check = {Q[0], Q_1};

        case(check)
            2'b01: A = A + M;
            2'b10: A = A - M;
            default: A = A;
        endcase

        {A,Q,Q_1} = {A[N-1], A, Q};
    end

    y = {A,Q};
end

endmodule



// NON RESTORING DIVIDER


module NonRestoring #(parameter N=16)(
    input [N-1:0] a,
    input [N-1:0] b,
    output reg [N-1:0] r,
    output reg [N-1:0] q
);

integer i;
reg [N:0] A;
reg [N-1:0] Q;
reg [N:0] M;

always @(*) begin
    A = 0;
    Q = a;
    M = {1'b0, b};

    for(i=0; i<N; i=i+1) begin
        {A,Q} = {A,Q} << 1;

        if(A[N])
            A = A + M;
        else
            A = A - M;

        Q[0] = ~A[N];
    end

    if(A[N])
        A = A + M;

    r = A[N-1:0];
    q = Q;
end

endmodule


// EUCLID GCD FSM


module EuclidGCD #(parameter N=16)(
    input clk,
    input reset,
    input start,
    input [N-1:0] a_in,
    input [N-1:0] b_in,
    output reg [N-1:0] gcd_out,
    output reg done
);

reg [N-1:0] a,b;

always @(posedge clk or posedge reset) begin
    if(reset) begin
        done <= 0;
        gcd_out <= 0;
        a <= 0;
        b <= 0;
    end
    else if(start) begin
        a <= a_in;
        b <= b_in;
        gcd_out <= 0;
        done <= 0;
    end
    else if(a != 0 && b != 0) begin
        if(a > b)
            a <= a - b;
        else
            b <= b - a;
    end
    else if(!done) begin
        gcd_out <= (a == 0) ? b : a;
        done <= 1;
    end
end

endmodule



// TOP CALCULATOR


module Calculator #(parameter N=16)(
    input clk,
    input reset,
    input start,
    input [N-1:0] A,
    input [N-1:0] B,
    input [2:0] opcode,

    output reg [2*N-1:0] Y,
    output reg done
);

localparam ADD = 3'b000;
localparam SUB = 3'b001;
localparam MUL = 3'b010;
localparam DIV = 3'b011;
localparam GCD = 3'b100;

wire [N:0] addsub_out;
wire [2*N-1:0] mult_out;
wire [N-1:0] div_q;
wire [N-1:0] div_r;
wire [N-1:0] gcd_out;
wire gcd_done;

AddSub #(N) addsub_inst(
    .A(A),
    .B(B),
    .mode(opcode == SUB),
    .Y(addsub_out)
);

Booths_algo #(N) mult_inst(
    .a(A),
    .b(B),
    .y(mult_out)
);

NonRestoring #(N) div_inst(
    .a(A),
    .b(B),
    .r(div_r),
    .q(div_q)
);

EuclidGCD #(N) gcd_inst(
    .clk(clk),
    .reset(reset),
    .start(start & (opcode == GCD)),
    .a_in(A),
    .b_in(B),
    .gcd_out(gcd_out),
    .done(gcd_done)
);

always @(*) begin
    done = 1'b1;

    case(opcode)

        ADD:
            Y = {{N{1'b0}}, addsub_out[N-1:0]};

        SUB:
            Y = {{N{addsub_out[N-1]}}, addsub_out[N-1:0]};

        MUL:
            Y = mult_out;

        DIV:
            Y = {{N{1'b0}}, div_q};

        GCD: begin
            Y = {{N{1'b0}}, gcd_out};
            done = gcd_done;
        end

        default: begin
            Y = 0;
            done = 0;
        end
    endcase
end

endmodule