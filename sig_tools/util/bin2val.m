function v = bin2val(b, dtype)

import java.nio.ByteBuffer;
bb=ByteBuffer.wrap(b);

switch lower(dtype)
    case 'float'
        n = length(b)/4;
        v = zeros(n, 1);
        fb = bb.asFloatBuffer();
        for ii=1:n
            v(ii) = fb.get();
        end
    case 'short'        
        n = length(b)/2;
        v = zeros(n, 1);
        ib = bb.asShortBuffer();
        for ii=1:n
            v(ii) = ib.get();
        end
    otherwise
        error('Unknown type %s', dtype)
end


% import java.io.DataInputStream;
% import java.io.ByteArrayInputStream;
% 
% dis = DataInputStream(ByteArrayInputStream(b));
% switch lower(dtype)
%     case 'float'
%         n = length(b)/4;
%         v = zeros(n, 1);        
%         for ii=1:n
%             v(ii) = dis.readFloat();
%         end
%     case 'short'        
%         n = length(b)/2;
%         v = zeros(n, 1);
%         for ii=1:n
%             v(ii) = dis.getShort();
%         end
%     otherwise
%         error('Unknown type %s', dtype)
% end
