module pcg;

    // Function to convert binary to gray code
    function [8:0] bin_to_gray(input [8:0] binary);
        begin
            bin_to_gray[8] = binary[8];
            bin_to_gray[7] = binary[8] ^ binary[7];
            bin_to_gray[6] = binary[7] ^ binary[6];
            bin_to_gray[5] = binary[6] ^ binary[5];
            bin_to_gray[4] = binary[5] ^ binary[4];
            bin_to_gray[3] = binary[4] ^ binary[3];
            bin_to_gray[2] = binary[3] ^ binary[2];
            bin_to_gray[1] = binary[2] ^ binary[1];
            bin_to_gray[0] = binary[1] ^ binary[0];
        end
    endfunction

    // Function to convert gray code to binary
    function [8:0] gray_to_bin(input [8:0] gray);
        begin
            gray_to_bin[8] = gray[8];
            gray_to_bin[7] = gray[8] ^ gray[7];
            gray_to_bin[6] = gray[8] ^ gray[7] ^ gray[6];
            gray_to_bin[5] = gray[8] ^ gray[7] ^ gray[6] ^ gray[5];
            gray_to_bin[4] = gray[8] ^ gray[7] ^ gray[6] ^ gray[5] ^ gray[4];
            gray_to_bin[3] = gray[8] ^ gray[7] ^ gray[6] ^ gray[5] ^ gray[4] ^ gray[3];
            gray_to_bin[2] = gray[8] ^ gray[7] ^ gray[6] ^ gray[5] ^ gray[4] ^ gray[3] ^ gray[2];
            gray_to_bin[1] = gray[8] ^ gray[7] ^ gray[6] ^ gray[5] ^ gray[4] ^ gray[3] ^ gray[2] ^ gray[1];
            gray_to_bin[0] = gray[8] ^ gray[7] ^ gray[6] ^ gray[5] ^ gray[4] ^ gray[3] ^ gray[2] ^ gray[1] ^ gray[0];
        end
    endfunction

endmodule
