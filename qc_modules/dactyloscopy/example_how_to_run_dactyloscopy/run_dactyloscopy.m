function run_dactyloscopy

dactyloscopy_data = '/cmap/data/vdb/dactyloscopy/';
lp = parse_tbl('list_of_plates.txt','outfmt','record')
ds_rnaseq = parse_gctx(fullfile(dactyloscopy_data, 'cline_rnaseq_n1022x12450.gctx'));
ds_affx = parse_gctx(fullfile(dactyloscopy_data, 'cline_affx_n1515x22268.gctx'));

for ii = 1:length(lp)
	disp(ii)
	try
		x(ii).result = dactyloscopy_single(get_gct_path(lp(ii).det_plate,...
			'QNORM',strcat('/cmap/obelix/pod/custom/',lp(ii).project,'/roast'),false),...
			'--cell_db',ds_rnaseq,'--cell_db_backup',ds_affx,...
			'--lm_probes',fullfile(dactyloscopy_data, 'lm_epsilon_n978.grp'),...
			'--lincs_lines',fullfile(dactyloscopy_data, 'ljp_rep_lincs_lines.grp'),...
			'--api_url','http://api.clue.io',...
			'--cell_line_dictionary',fullfile(dactyloscopy_data, 'derived_cell_lines.txt'),...
			'--api_user_key_file','api_user_key.grp',...
			'--ambiguous_clines',fullfile(dactyloscopy_data, 'list_of_ambiguous_cell_lines.txt'),...
			'--save_out',false);
		x(ii).dactyloscopy_success = true;
	catch ME
		disp(ME)
		x(ii).result = {};
		x(ii).dactyloscopy_success = false;
	end
end

save('results_all.mat','x')
quit
