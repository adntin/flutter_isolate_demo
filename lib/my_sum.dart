//计算 0 到 num 数值的总和
num mySum(int num) {
  int count = 0;
  while (num > 0) {
    count = count + num;
    num--;
  }
  return count;
}
