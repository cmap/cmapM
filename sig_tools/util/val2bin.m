function b = val2bin(v, dtype)

import java.nio.ByteBuffer
n = length(v);
switch(lower(dtype))
    case 'float'
        bb = ByteBuffer.allocate(n*4);
        bb.asFloatBuffer().put(v);
    case 'short'        
        bb= ByteBuffer.allocate(n*2);
        bb.asShortBuffer().put(int16(v));
    otherwise
        error('Unknown data type: %s', dtype);
end
    b = bb.array();


% import java.io.ByteArrayOutputStream;
% import java.io.DataOutputStream;



%  public static byte[] encodeFloatArray(float[] array) {
%     try {
%         ByteArrayOutputStream bytes = new ByteArrayOutputStream(4 * array.length);
%         DataOutputStream os = new DataOutputStream(bytes);
% 
%         for (int i = 0, length = array.length; i < length; i++) {
%         os.writeFloat(array[i]);
%         }
%         os.close();
%         return bytes.getBuffer();
%     } catch (IOException e) {
%         e.printStackTrace();
%         return null;
%     }
%     }