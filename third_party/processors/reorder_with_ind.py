import numpy as np

def to_int(k):
    return [int(k[0]), int(k[1])]
    

def reorder(alignments, src_lines):
    alignment_inds = list()
    srcs = list()
    reordered = list()
    sent_ids = list()
    for index, (line, align) in enumerate(zip(src_lines, alignments)):
        if type(line)==list:
            src = line
        else:
            src = line.strip().split(' ')

        align = align[:-1].split(' ')
        pairs = list()
        for pair in align:
            try:
                pairs.append(to_int(pair.split('-')))
            except:
                continue
        pairs = sorted(pairs, key=lambda k: k[0])
        
        alignment_tuples = dict()
        for i in range(len(pairs)):
            try:
                alignment_tuples[pairs[i][0]].append(pairs[i][1])
            except:
                alignment_tuples[pairs[i][0]] = [pairs[i][1]]


        src_inds = list(alignment_tuples.keys())
        for i in range(len(src)):
            if i not in src_inds:
                if i == 0:
                    try:
                        alignment_tuples[0] = alignment_tuples[src_inds[0]]
                    except:
                        import pdb; pdb.set_trace()
                else:
                    alignment_tuples[i] = alignment_tuples[i - 1]


        for key in alignment_tuples.keys():
            alignment_tuples[key] = sorted(alignment_tuples[key])

        src_inds = list(alignment_tuples.keys())

        alignment_ind = list()
        for i in range(len(src)):

            if len(src[i]) > 1:
                if src[i].endswith('.'):
                    src[i] = src[i][:-1]

            alignment_ind.append(alignment_tuples[i][0])

        alignment_inds.append(np.argsort(alignment_ind))

        src_reordered = np.array(src)[alignment_inds[-1]]
        reordered.append(' '.join(src_reordered)) 
    return reordered, alignment_inds

def reorder_2_sent(alignment_file, text_a, text_b):
    text_a_reordered, _ = reorder(alignment_file[:len(text_a)], text_a)
    text_b_reordered, _ = reorder(alignment_file[-len(text_b):], text_b)
    return text_a_reordered, text_b_reordered

def reorder_1_sent_with_labels(alignment_file, text, label):
    _, reordered_idx = reorder(alignment_file, text)
    res_text, res_label = list(), list()
    for i in range(len(reordered_idx)):
        res_text.append(np.array(text[i])[reordered_idx[i]])
        res_label.append(np.array(label[i])[reordered_idx[i]])
    
    return res_text, res_label
 