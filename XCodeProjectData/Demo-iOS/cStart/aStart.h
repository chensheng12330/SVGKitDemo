#pragma once

#ifndef ALGORITHMS_H
#define ALGORITHMS_H
// CAlgorithms

enum{WIDE=40,LENGTH=40};//定义数组最大范围值大小
enum{VIABLE, WALL, INOPEN, INCLOSE, STARTPOINT, DESTINATION};

//定义数组实际内容大小
static int _gFactLENGTH=LENGTH; //Y  纵向，对应Y坐标轴
static int _gFactWIDE  =WIDE;   //X  横向，对应X坐标轴

//瓦片节点
struct TNode
{
	//char perperty;// 属性， 是墙还是起点或是其他
	int    flag; //标志位 0 为可走， 1 为墙壁  2 在penlist
    //3 在 closelist中 4 为起点 5 为终点
	unsigned int location_x;
	unsigned int location_y;
	unsigned int value_h;
	unsigned int value_g;
	unsigned int value_f;
	struct TNode* parent;
    
};
typedef struct TNode TNode;


/////////////////////////////////////////////////////////////
//   创建 closelist
////////////////////////////////////////////////////////////
struct CloseList
{
	struct TNode *closenode;
	struct CloseList* next;
};
typedef struct CloseList CloseList;

///////////////////////////////////////////////////////////////
// 创建 openlist
//////////////////////////////////////////////////////////////
struct OpenList
{
	struct TNode *opennode;
	struct OpenList* next;
};
typedef struct OpenList OpenList;


int startpoint_x; //横坐标
int startpoint_y; //纵坐标

int endpoint_x;
int endpoint_y;

TNode m_node[LENGTH][WIDE];  //LENGTH-列， WIDE-行


/*!
 设置NodeMap实际值容易范围
 @param   width  实际二维数组宽度，须小于数组范围
 @param   length 实际二维数组宽度，须小于数组范围
 @return  void
 */
void SetFactNodeMapSize(int width, int length);

/*!
 初使化NodeMap,将字符二维数据转换成NodeMap链表结构
 @param   charMap 字符二维数组, [.] => 可行格 [s] =>起点  [d] =>终点 [x] =>墙,不可行格
 @param   open    打开链表
 @return  void
 */
void InitNodeMap( char charMap[][WIDE], OpenList *open);


/*!
 启动路径查找
 @param   open    打开列表，用于装载可通过节点
 @param   close   关闭列表，用于装载已确定的路径节点
 @param   charMap 字符二维数组,
 @return  int      0 =>未找到   1=>找到可行路径
 */
int FindDestinnation(OpenList* open,CloseList* close);


int Insert2OpenList(OpenList* , int x, int y);

/*!
 节点判断类功能函数，对节点的相关信息核对
 @param   x轴 下标点
 @param  y轴  下标点
 @return BOOL 成功标识
 */
int IsInOpenList(OpenList*, int x, int y);
int IsInCloseList(OpenList*, int x, int y);
void IsChangeParent(OpenList*, int x, int y);
int IsAviable(OpenList* , int x, int y);

/*!
 算法类功能函数，查路所需
 @param
 @return
 */
unsigned int DistanceManhattan(int d_x, int d_y, int x, int y);

unsigned int  Euclidean_dis(int sx,int sy,int ex,int ey);//欧几里德

unsigned int  Chebyshev_dis(int sx,int sy,int ex,int ey);//切比雪夫

unsigned int  jiaquan_Manhattan(int sx,int sy,int ex,int ey);//加权曼哈顿   //better


#endif
