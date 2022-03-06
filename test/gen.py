print('rule numbers {')
print('    %run dag')
nums = list(range(2, 20))
for i in nums:
    for j in nums:
        print(f'    {i}*{j} -> {i*j}')
print('}')
print('rule start : numbers {}')