CKPT_DIR = 6B_500
OUTPUT_DIR = 6B2_yn
TRAIN_DATA = BioASQ/train/BioASQ-train-6b.json 
TEST_DATA = BioASQ/yesno/BioASQ-test-yesno-6b-2.json
# EVAL_DATA = BioASQ/official/Task6BGoldenEnriched/6B1_golden.json


# Factoid train / test / convert / eval
f_train:
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

f_test:
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

f_convert:
	python biocodes/transform_nbset2bioasqform.py \
	--nbest_path=$(OUTPUT_DIR)/nbest_predictions.json \
	--output_path=$(OUTPUT_DIR)

f_eval:
	cd Evaluation-Measures && java -Xmx10G \
	-cp flat/BioASQEvaluation/dist/BioASQEvaluation.jar evaluation.EvaluatorTask1b -phaseB -e 5 \
	$(BIOBERT_DIR)/$(EVAL_DATA) \
	../$(OUTPUT_DIR)/BioASQform_BioASQ-answer.json


# YesNo test / merge / thresh / eval => required argument: threshold
yn_test:
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

yn_merge:
	python merge_yesno.py \
	$(BIOBERT_DIR)/$(TEST_DATA) \
	$(OUTPUT_DIR)/null_odds.json \
	$(BIOBERT_DIR)/$(TEST_DATA)_merged \
	$(OUTPUT_DIR)/null_odds.json_merged

yn_thresh:
	python thresh_yesno.py \
	$(BIOBERT_DIR)/$(TEST_DATA)_merged \
	$(OUTPUT_DIR)/null_odds.json_merged \
	-n $(OUTPUT_DIR)/null_odds.json_merged \
	-t $(threshold)

yn_eval:
	python eval_yesno.py \
	$(OUTPUT_DIR)/null_odds.json_merged \
	$(OUTPUT_DIR)/$(OUTPUT_DIR)_result.json \
	--eval_file $(BIOBERT_DIR)/$(TEST_DATA)_merged \
	--threshold $(threshold)
