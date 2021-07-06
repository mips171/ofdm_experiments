% supress octave warnings
warning('off', 'all');
ALLOW_REPEATING_SNR_VALUES = true;

NUMBER_OF_TRIALS = 100;
MIN_SNR = -3;
MAX_SNR = 30;

if ALLOW_REPEATING_SNR_VALUES 
    % allow repeating random numbers, to be more realistic
    % Define modulation order
    RANDOM_SNR = randi([MIN_SNR MAX_SNR], 1, NUMBER_OF_TRIALS);
else 
    % get non-reapeating random numbers so the charts work (must be run from octave gui)
    randn();
    numSequences = 1; % Choose how many sequences you want here
    maxNumber = NUMBER_OF_TRIALS * 2; % Specify how many numbers to possibly generate from
    subsetNumber = NUMBER_OF_TRIALS; % How many numbers you want to select from the list of numbers
    RANDOM_SNR = arrayfun(@(x) randperm(maxNumber, subsetNumber) - 3, 1:numSequences, 'uni', 0);
    RANDOM_SNR = cell2mat(RANDOM_SNR.');
end

global ALL_MOD_ORDERS = [ 2, 4, 16, 64 ];
global mod_order = 1;
CURRENT_MOD_ORDER = ALL_MOD_ORDERS(mod_order);

%% if BER is high twice, lower the MOD order
%% if BER is low twice, raise the MOD order

%% this will work when SNR is relatively stable, but not if SNR is very unstable
%% if SNR very unstable it is best to stick to a lower MOD order

function [ mod_order ] = adapt_modulation_order_ber(BER, mod_order)

    if ge(BER, 0.5)
        if isequal(mod_order, 1)
            fprintf( 'Cannot go lower than BPSK in this simulation.\n' );
        else
            mod_order = mod_order - 1;
            fprintf ( 'Bit error rate %f, reducing modulation order\n', BER);
        end
    else
        if isequal(mod_order, 4)
            mod_order = mod_order; % do nothing
        else
            mod_order = mod_order + 1;
            fprintf ( 'Bit error rate %f, increasing modulation order\n', BER);
        end
    end
end

function [ mod_order ] = adapt_modulation_order_snr(SNR_simulated, mod_order)

    if le(SNR_simulated, 10) & ge(mod_order, 2)
        fprintf ( 'SNR too low for current modulation rate. %d, reducing modulation order\n', SNR_simulated);
        mod_order = mod_order - 1;
    end

    if le(SNR_simulated, 20) & ge(mod_order, 3)
        fprintf ( 'SNR too low for current modulation rate. %d, reducing modulation order\n', SNR_simulated);
        mod_order = mod_order - 1;
    end

end 

%% MODULATION_ORDER = [ 2,  2, 2, 4, 4, 2, 2, 4, 16, 64]
% Define simulated SNR value
#SNR_simulated =    [-3, -1, 0, 1, 1, 3, 5, 10, 15, 5, 5, 10, 20, 30 ];
SNR_simulated = RANDOM_SNR;
fprintf( 'Random SNR is: %d\n', SNR_simulated);
SNR_decoded = [];
BER_decoded = [];
result = [];

for i = 1 : length( SNR_simulated )
    fprintf( 'Adapting modulation order based on SNR.\n Current mod order: %d\n', ALL_MOD_ORDERS( mod_order ) );
    fprintf( 'SNR: %f\n', SNR_simulated( i ) );
    mod_order = adapt_modulation_order_snr(SNR_simulated( i ), mod_order);
    fprintf( 'New mod order: %d\n', ALL_MOD_ORDERS( mod_order ) );

    signal_gen( SNR_simulated( i ), ALL_MOD_ORDERS( mod_order ) );
    [ SNR , BER ] = decode( SNR_simulated( i ), ALL_MOD_ORDERS( mod_order )  );
    result = [ result ; [ SNR , BER ] ];

    fprintf( 'Adapting modulation order based on bit error rate.\n Current mod order: %d\n', ALL_MOD_ORDERS( mod_order ) );
    fprintf( 'Bit error rate: %f\n', BER );
    mod_order = adapt_modulation_order_ber(BER, mod_order);
    fprintf( 'New mod order: %d\n', ALL_MOD_ORDERS( mod_order ) );
end

for i = 1 : length( SNR_simulated )
    SNR_decoded = [ SNR_decoded , result( i , 1 ) ];
    BER_decoded = [ BER_decoded , result( i , 2 ) ];
end

% Step 5 - Plot SNR and BER
figure( 8 ); 
clf;

subplot( 2 , 1 , 1 );
bh = bar( SNR_simulated , SNR_decoded );
shading flat;
set( bh , 'FaceColor' , [ 0 , 0 , 1 ] );
%axis( [ min( SNR_simulated ) , max( SNR_simulated ) , 0 , max( SNR_decoded ) ] );
grid on;
title( 'SNR decoded' );
xlabel( 'Simulated SNR (dB)' );
ylabel( 'Actual SNR (dB)' );

subplot( 2 , 1 , 2 );
bh = bar( SNR_simulated , BER_decoded );
shading flat;
set( bh , 'FaceColor' , [ 0 , 0 , 1 ] );
%axis( [ min( SNR_simulated ) , max( SNR_simulated ) , 0 , max( BER_decoded ) + 5 ] );
grid on;
title( 'BER decoded' );
xlabel( 'Simulated SNR (dB)' );
ylabel( 'BER' );
