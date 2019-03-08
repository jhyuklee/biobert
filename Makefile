# OUTPUT_DIR = QA_output
CKPT_DIR = 7B_500
OUTPUT_DIR = 7B1_yn
# OUTPUT_DIR = yesno_test
TRAIN_DATA = BioASQ/train/BioASQ-train-6b.json 
# TEST_DATA = BioASQ/test/BioASQ-test-NA-6b-1.json
# TEST_DATA = BioASQ/test/BioASQ-test-NA-4b-1.json
TEST_DATA = BioASQ/yesno/BioASQ-test-yesno-NA-7b-1.json
# EVAL_DATA = BioASQ/official/Task6BGoldenEnriched/6B1_golden.json
EVAL_DATA = BioASQ/4B1_golden.json


qa_train:
	python run_qa.py \
	--do_train=True \
	--vocab_file=$(BIOBERT_DIR)/biobert_pmc/vocab.txt \
	--bert_config_file=$(BIOBERT_DIR)/biobert_pmc/bert_config.json \
	--init_checkpoint=$(BIOBERT_DIR)/BERT-pubmed-pmc-470000-SQuAD/model.ckpt-14599 \
	--max_seq_length=384 \
	--train_batch_size=12 \
	--learning_rate=1e-5 \
	--doc_stride=128 \
	--num_train_epochs=50.0 \
	--do_lower_case=False \
	--train_file=$(BIOBERT_DIR)/$(TRAIN_DATA) \
	--output_dir=$(CKPT_DIR)

qa_test:
	python run_qa.py \
	--do_predict=True \
	--vocab_file=$(BIOBERT_DIR)/biobert_pmc/vocab.txt \
	--bert_config_file=$(BIOBERT_DIR)/biobert_pmc/bert_config.json \
	--init_checkpoint=$(CKPT_DIR)/model.ckpt-500 \
	--max_seq_length=384 \
	--train_batch_size=12 \
	--learning_rate=1e-5 \
	--doc_stride=128 \
	--num_train_epochs=50.0 \
	--do_lower_case=False \
	--predict_file=$(BIOBERT_DIR)/$(TEST_DATA) \
	--output_dir=$(OUTPUT_DIR)

qa_test_yn:
	python run_qa.py \
	--do_predict=True \
	--vocab_file=$(BIOBERT_DIR)/biobert_pmc/vocab.txt \
	--bert_config_file=$(BIOBERT_DIR)/biobert_pmc/bert_config.json \
	--init_checkpoint=$(CKPT_DIR)/model.ckpt-500 \
	--max_seq_length=384 \
	--train_batch_size=12 \
	--learning_rate=1e-5 \
	--doc_stride=128 \
	--num_train_epochs=50.0 \
	--do_lower_case=False \
	--predict_file=$(BIOBERT_DIR)/$(TEST_DATA) \
	--output_dir=$(OUTPUT_DIR) \
	--version_2_with_negative

qa_merge:
	python merge_yesno.py \
	$(BIOBERT_DIR)/$(TEST_DATA) \
	$(OUTPUT_DIR)/null_odds.json \
	$(BIOBERT_DIR)/$(TEST_DATA)_merged \
	$(OUTPUT_DIR)/null_odds.json_merged

qa_eval2:
	python evaluate-v2.0.py \
	$(BIOBERT_DIR)/$(TEST_DATA)_merged \
	$(OUTPUT_DIR)/null_odds.json_merged \
	-n $(OUTPUT_DIR)/null_odds.json_merged

qa_convert2:
	python convert_yesno.py \
	$(OUTPUT_DIR)/null_odds.json_merged \
	$(OUTPUT_DIR)/$(OUTPUT_DIR)_result.json \
	--eval_file $(BIOBERT_DIR)/$(TEST_DATA)_merged \
	--threshold $(threshold)

# Deprecated
# qa_convert:
# 	python biocodes/transform_nbset2bioasqform.py \
# 	--nbest_path=$(OUTPUT_DIR)/nbest_predictions.json \
# 	--output_path=$(OUTPUT_DIR)

# qa_eval:
# 	cd Evaluation-Measures && java -Xmx10G -cp flat/BioASQEvaluation/dist/BioASQEvaluation.jar evaluation.EvaluatorTask1b -phaseB -e 5 \
# 	$(BIOBERT_DIR)/$(EVAL_DATA) \
# 	../$(OUTPUT_DIR)/BioASQform_BioASQ-answer.json
