import itertools

n=0
print('Enter list of items (separated by commas):')
list=input()
list=list.replace(' ', '').split(',')
li=[]
for i in list:
	li.append(str(i))
for L in range(0, len(list)+1):
    for subset in itertools.combinations(list, L):
        print(subset)
        n += 1
print('Number of combinations: ' + str(n-1)) #-1 because combination of 0 items is also counted, but unwanted