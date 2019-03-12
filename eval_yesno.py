import json
import os
import argparse
import random

from tqdm import tqdm


def evaluate(args):
    with open(args.na_prob_file, 'r') as fp:
        na_probs = json.load(fp)

    # Make official json outfile
    out_json = {}
    for qid in na_probs:
        if na_probs[qid] > args.threshold:
            out_json[qid] = 'no'
        else:
            out_json[qid] = 'yes'

    with open(args.out_path, 'w') as fp:
        json.dump(out_json, fp)
    print('Official evaluation file dumped as {}'.format(args.out_path))

    # If gold standard is not given, exit.
    if not os.path.exists(args.eval_file):
        return

    # Eval with gold standard
    with open(args.eval_file, 'r') as fp:
        data = json.load(fp)['data']
    qid2ans = {} 
    for article in data:
        for paragraph in article['paragraphs']:
            for qa in paragraph['qas']:
                if 'answers' in qa:
                    qid2ans[qa['id']] = qa['answers']

    # Yes/No F1
    total = 0
    correct = 0
    yes = {'tp': 0, 'fp': 0, 'fn':0, 'tn':0}
    no = {'tp': 0, 'fp': 0, 'fn':0, 'tn':0}
    for qid, gt in qid2ans.items():
        total += 1
        correct += int(gt == out_json[qid])
        if out_json[qid] == 'yes':
            if out_json[qid] == gt:
                yes['tp'] += 1
                no['tn'] += 1
            else:
                yes['fp'] += 1
                no['fn'] += 1
        else:
            if out_json[qid] == gt:
                yes['tn'] += 1
                no['tp'] += 1
            else:
                yes['fn'] += 1
                no['fp'] += 1

    yes_pr = yes['tp'] / (yes['tp'] + yes['fp'] + 1e-9) 
    yes_re = yes['tp'] / (yes['tp'] + yes['fn'] + 1e-9) 
    yes_f1 = 2 * yes_pr * yes_re / (yes_pr + yes_re + 1e-9)
    no_pr = no['tp'] / (no['tp'] + no['fp'] + 1e-9)
    no_re = no['tp'] / (no['tp'] + no['fn'] + 1e-9) 
    no_f1 = 2 * no_pr * no_re / (no_pr + no_re + 1e-9)
    print('Accuracy: {}'.format(correct/total))
    print('Yes F1: {}'.format(yes_f1))
    print('No F1: {}'.format(no_f1))
    print('Macro F1: {}'.format((yes_f1+no_f1)/2))


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('na_prob_file')
    parser.add_argument('out_path')
    parser.add_argument('--eval_file', type=str, default='')
    parser.add_argument('--threshold', type=float, default=0.0)

    return parser.parse_args()


def main():
    args = get_args()
    evaluate(args)


if __name__ == '__main__':
    main()
