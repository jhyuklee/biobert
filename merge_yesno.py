import json
import os
import argparse
import random

from tqdm import tqdm


def p_counter(data):
    p_cnt = 0
    for article in data:
        for paragraph in article['paragraphs']:
            p_cnt += 1
    return p_cnt


def merge(args):
    # Prepare datasets and na-probs
    with open(args.gt_file, 'r') as fp:
        data = json.load(fp)['data']
    with open(args.na_prob_file, 'r') as fp:
        na_probs = json.load(fp)
    qid2ans = {} 
    for article in data:
        for paragraph in article['paragraphs']:
            for qa in paragraph['qas']:
                if 'answers' in qa:
                    qid2ans[qa['id']] = qa['answers']
                else:
                    qid2ans[qa['id']] = 'yes'
    assert set(qid2ans.keys()) == set(na_probs.keys())

    # Merge them using a single qid
    merge_score = {}
    merge_cnt = {}
    for qid in qid2ans:
        out_qid = qid.split('_')[0]
        if not out_qid in merge_score:
            merge_score[out_qid] = []
            merge_cnt[out_qid] = 0.0
        merge_score[out_qid].append(na_probs[qid])
        merge_cnt[out_qid] += 1

    assert len(qid2ans) == sum([k for k in merge_cnt.values()])
    merge_score = {qid: sum(merge_score[qid])/merge_cnt[qid] for qid in merge_score}
    # merge_score = {qid: min(merge_score[qid]) for qid in merge_score}

    # Dump na_prob json
    with open(args.na_prob_out_path, 'w') as fp:
        json.dump(merge_score, fp)

    # New dataset without duplicates
    checker = []
    to_data = []
    for article in data:
        to_article = {'paragraphs': [], 'title': article['title']}
        for paragraph in article['paragraphs']:
            assert len(paragraph['qas']) == 1
            out_qid = paragraph['qas'][0]['id'].split('_')[0]

            if out_qid in checker:
                continue
            else:
                checker.append(out_qid)
                paragraph['qas'][0]['id'] = out_qid
                to_article['paragraphs'].append({'context': paragraph['context'], 'qas': paragraph['qas']})

        to_data.append(to_article)

    # Dump new dataset json
    with open(args.gt_out_path, 'w') as fp:
        json.dump({'data': to_data}, fp)


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('gt_file')
    parser.add_argument('na_prob_file')
    parser.add_argument('gt_out_path')
    parser.add_argument('na_prob_out_path')

    return parser.parse_args()


def main():
    args = get_args()
    merge(args)


if __name__ == '__main__':
    main()
