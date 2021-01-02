function doses = get_serial_dilution(n, start_dose, fold_change)
% GET_SERIAL_DILUTION Calculate doses in a dilution series
% D = GET_SERIAL_DILUTION(N, ST, FC)

doses = exp(log(start_dose)-(0:(n-1))*log(fold_change))';

end