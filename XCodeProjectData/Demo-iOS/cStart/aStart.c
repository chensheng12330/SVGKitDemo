//
//  aStart.c
//  AStar
//
//  Created by sherwin.chen on 14-8-23.
//  Copyright (c) 2014年 sherwin. All rights reserved.
//

// Algorithms.cpp : 实现文件
//


#include "aStart.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

// CAlgorithms

///////////////////////////////////////////////////////////
//			A*算法  最优寻路算法
//			算法是一种静态路网中求解最短路最有效的算法
//				1）公式表示为： f(n)=g(n)+h(n),
//				2） 加入最优路径修正
//						如果某个相邻的方格已经在 open list 中，则检查这条路径是否更优，
//						也就是说经由当前方格 ( 我们选中的方格 ) 到达那个方格是否具有更小的 G 值。
//						如果没有，不做任何操作。
//												作者：一路向南
//															2013, 5,10
/////////////////////////////////////////////////////////

const int DISTANCE=10;
const int direction[8][2]={{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}};// 方向

#define true  1
#define false 0

void AddNode2Open(OpenList* openlist, TNode* node)
{
	if(openlist ==NULL)
	{
		//MessageBox("没有");//no data in openlist!
        
		return;
	}
	if(node->flag!=STARTPOINT)
	{
		node->flag= INOPEN;
	}
	OpenList* temp =  malloc(sizeof(OpenList)); //OpenList;
	temp->next=NULL;
	temp->opennode = node;
    
    //	if(openlist->next==NULL)
    //	{openlist->next = temp;return;}
    
	while(openlist->next != NULL)
	{
		if(node->value_f < openlist->next->opennode->value_f)
		{
			OpenList* tempadd= openlist->next;
			temp->next= tempadd;
			openlist->next = temp;
			break;
		}
		else
			openlist= openlist->next;
	}
	openlist->next = temp;
    
}

// openlist 此处必须为指针的引用
void AddNode2Close(CloseList* close, OpenList** popen)
{
    //OpenList *open = (*popen);
	if(popen==NULL)
	{
        //		cout<<"no data in openlist!"<<endl;
        printf("no data in openlist!");
		return;
	}
	if((*popen)->opennode->flag != STARTPOINT)
		(*popen)->opennode->flag =INCLOSE;
    
	if(close->closenode == NULL)
	{
		close->closenode = (*popen)->opennode;
		OpenList* tempopen=(*popen);
		(*popen)=(*popen)->next;
		//open->opennode=NULL;
        //	open->next=NULL;
		free(tempopen);
		return;
	}
	while(close->next!= NULL)
		close= close->next;
    
	CloseList* temp= malloc(sizeof(CloseList));
	temp->closenode = (*popen)->opennode;
	temp->next=NULL;
	close->next= temp;
    
	OpenList* tempopen=(*popen);
	(*popen)=(*popen)->next;
	free( tempopen);
}

////////////////////////////////////////////////////////
//   查找类
///////////////////////////////////////////////////////

int FindDestinnation(OpenList* open,CloseList* close)
{
	Insert2OpenList(open,startpoint_y,startpoint_x);// 起点
	AddNode2Close(close,&open);// 起点放到 close中
    
    if (open==NULL) {
        return true;
    }
    
	while(!Insert2OpenList(open,open->opennode->location_y, open->opennode->location_x))
	{
		AddNode2Close(close,&open);
		if(open==NULL)
		{
			//MessageBox("未找到出口！地图有误");
			return false;
		}
	}
	return true;
	/*
     Node *tempnode = &m_node[endpoint_x][endpoint_y];
     while(tempnode->parent->flag!=STARTPOINT)
     {
     tempnode=tempnode->parent;
     aa[tempnode->location_x][tempnode->location_y]='@';
     }
     */
    
}
//////////////////////////////////////////////////////////////////////////
//  将临近的节点加入 openlist中
//				0      1      2
//				3      S      4
//				5      6      7
/////////////////////////////////////////////////////////////////////////////
int Insert2OpenList(OpenList* open,int center_x, int center_y)
{
	
	//while()
	//int counts
	//static int counts=0;
	//counts++;
	for(int i=0; i<8 ; i++)
	{
		int new_x=center_x + direction[i][0];
		int new_y=center_y+ direction[i][1];
        
		if(new_x>=0 && new_y>=0 && new_x<_gFactLENGTH &&
           new_y<_gFactWIDE &&
           IsAviable(open, new_x, new_y))// 0
		{
			if(	m_node[new_x][new_y].flag==DESTINATION)
			{
				m_node[new_x][new_y].parent = &m_node[center_x][center_y];
				return true;
			}
			m_node[new_x][new_y].flag =INOPEN;
			m_node[new_x][new_y].parent = &m_node[center_x][center_y];
			m_node[new_x][new_y].value_h =
            DistanceManhattan(endpoint_x, endpoint_y, new_x,new_y);//曼哈顿距离
            
			if(0==i || 2==i||5==i||7==i)
				m_node[new_x][new_y].value_g = m_node[center_x][center_y].value_g+14;
			else
				m_node[new_x][new_y].value_g = m_node[center_x][center_y].value_g+10;
            
			m_node[new_x][new_y].value_f = m_node[new_x][new_y].value_g+m_node[new_x][new_y].value_h;
            
			AddNode2Open(open, &m_node[new_x][new_y]);// 加入到 openlist中
		}
	}
	IsChangeParent(open, center_x,  center_y);
	//if(counts>1000)
	//	return true;
	//else
	return false;
}
// 是否有更好的路径
void IsChangeParent(OpenList* open,int center_x, int center_y)
{
	int i=0;
	for(; i<8 ; i++)
	{
		int new_x=center_x + direction[i][0];
		int new_y=center_y+ direction[i][1];
		if(new_x>=0 && new_y>=0 && new_x<LENGTH &&
           new_y<WIDE &&
           IsInOpenList(open, new_x, new_y))// 0
		{
            
			if(0==i|| 2==i|| 5==i|| 7==i)
			{
				if(m_node[new_x][new_y].value_g >  m_node[center_x][center_y].value_g+14)
				{
					m_node[new_x][new_y].parent = &m_node[center_x][center_y];
					m_node[new_x][new_y].value_g =   m_node[center_x][center_y].value_g+14;
				}
			}
			else
			{
				if(m_node[new_x][new_y].value_g >   m_node[center_x][center_y].value_g+10)
				{
					m_node[new_x][new_y].parent = &m_node[center_x][center_y];
					m_node[new_x][new_y].value_g =   m_node[center_x][center_y].value_g+10;
				}
			}
		}
	}
}

int IsAviable(OpenList* open, int x, int y)
{
	if(IsInOpenList( open, x, y))
		return false;
	if(IsInCloseList( open, x, y))
		return false;
	if(m_node[x][y].flag == WALL )
		return false;
	else
		return true;
}
int IsInOpenList(OpenList* openlist, int x,int y)
{
	if(m_node[x][y].flag == INOPEN)
		return true;
	else
		return false;
}

int IsInCloseList(OpenList* openlist, int x,int y)
{
	if(m_node[x][y].flag == INCLOSE|| m_node[x][y].flag==STARTPOINT)
		return true;
	else
		return false;
}

////////////////////////////////////////////////////////
//         选择计算距离的方法
//         默认选择  麦哈顿方法
//			可自行修改
////////////////////////////////////////////////////////
unsigned int DistanceManhattan(int d_x, int d_y, int x, int y)
{
	unsigned int temp=(abs(d_x - x) + abs(d_y-y))*DISTANCE;
	return temp;
}

unsigned int  Euclidean_dis(int sx,int sy,int ex,int ey){//欧几里德
	double nn;
	nn=sqrt((float)((sx-ex)*(sx-ex)+(sy-ey)*(sy-ey)));
	return nn;
}

unsigned int  Chebyshev_dis(int sx,int sy,int ex,int ey){//切比雪夫
	double nn;
	//nn=max(abs(sx-ex),abs(sy-ey));
	return nn;
}

unsigned int  jiaquan_Manhattan(int sx,int sy,int ex,int ey){//加权曼哈顿   //better
	double nn,dx,dy;
	dx=abs(sx-ex);
	dy=abs(sy-ey);
	if(dx>dy)
		nn=10*dx+6*dy;
	else
		nn=6*dx+10*dy;
	return nn;
}

void SetFactNodeMapSize(int width, int length)
{
    if (width<0 || width>WIDE || length<0 || length>LENGTH) {
        
        assert(0);
        //数据越界...
        return;
    }
    
    _gFactLENGTH = length;
    _gFactWIDE   = width;
    
    return;
}

//初始化 node
void InitNodeMap( char charMap[][WIDE], OpenList * openlist)
{
	for(int i=0; i<= _gFactLENGTH; i++) //列
	{
		for(int j=0; j<= _gFactWIDE; j++) //行
		{
            TNode *node = malloc(sizeof(TNode));
            node->flag = 0;
            node->value_h= 0;
            node->value_g= 0;
            node->value_f =  0;
            node->parent= NULL;
            
            m_node[i][j] =  *node;
			m_node[i][j].location_x = j;
			m_node[i][j].location_y = i;
			m_node[i][j].parent = NULL;

            //外围墙设置
            if (i==_gFactLENGTH || j==_gFactWIDE) {
                m_node[i][j].flag = WALL;
                charMap[i][j] = 'x';
                continue;
            }
            
			switch(charMap[i][j])
			{
                case '.':
                    m_node[i][j].flag = VIABLE;
                    break;
                case 'x':
                    m_node[i][j].flag = WALL;
                    break;
                case 's':
                    m_node[i][j].flag = STARTPOINT;
                    openlist->next=NULL;
                    openlist->opennode= &m_node[i][j];//  将起点放到 OPenList中
                    startpoint_y= i;
                    startpoint_x= j;
                    break;
                case 'd':
                    m_node[i][j].flag = DESTINATION;
                    endpoint_y= i;
                    endpoint_x= j;
                    
                    break;
			}
		}
	}
}


