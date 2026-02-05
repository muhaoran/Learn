#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简单的待办事项管理应用
支持添加、查看、完成和删除任务
"""

import json
import os
from datetime import datetime


class TodoApp:
    def __init__(self, filename='todos.json'):
        self.filename = filename
        self.todos = self.load_todos()
    
    def load_todos(self):
        """从文件加载待办事项"""
        if os.path.exists(self.filename):
            with open(self.filename, 'r', encoding='utf-8') as f:
                return json.load(f)
        return []
    
    def save_todos(self):
        """保存待办事项到文件"""
        with open(self.filename, 'w', encoding='utf-8') as f:
            json.dump(self.todos, f, ensure_ascii=False, indent=2)
    
    def add_todo(self, task):
        """添加新的待办事项"""
        todo = {
            'id': len(self.todos) + 1,
            'task': task,
            'completed': False,
            'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        self.todos.append(todo)
        self.save_todos()
        print(f"✓ 已添加任务: {task}")
    
    def list_todos(self):
        """列出所有待办事项"""
        if not self.todos:
            print("目前没有待办事项！")
            return
        
        print("\n📋 待办事项列表:")
        print("-" * 60)
        for todo in self.todos:
            status = "✅" if todo['completed'] else "⏳"
            print(f"{status} [{todo['id']}] {todo['task']}")
            print(f"   创建时间: {todo['created_at']}")
        print("-" * 60)
    
    def complete_todo(self, todo_id):
        """标记待办事项为完成"""
        for todo in self.todos:
            if todo['id'] == todo_id:
                todo['completed'] = True
                self.save_todos()
                print(f"✓ 已完成任务: {todo['task']}")
                return
        print(f"✗ 未找到ID为 {todo_id} 的任务")
    
    def delete_todo(self, todo_id):
        """删除待办事项"""
        for i, todo in enumerate(self.todos):
            if todo['id'] == todo_id:
                deleted_task = self.todos.pop(i)
                # 重新编号
                for j, t in enumerate(self.todos):
                    t['id'] = j + 1
                self.save_todos()
                print(f"✓ 已删除任务: {deleted_task['task']}")
                return
        print(f"✗ 未找到ID为 {todo_id} 的任务")
    
    def run(self):
        """运行主程序"""
        print("=" * 60)
        print("📝 欢迎使用待办事项管理应用")
        print("=" * 60)
        
        while True:
            print("\n请选择操作:")
            print("1. 添加任务")
            print("2. 查看任务")
            print("3. 完成任务")
            print("4. 删除任务")
            print("5. 退出")
            
            choice = input("\n请输入选项 (1-5): ").strip()
            
            if choice == '1':
                task = input("请输入任务内容: ").strip()
                if task:
                    self.add_todo(task)
                else:
                    print("✗ 任务内容不能为空")
            
            elif choice == '2':
                self.list_todos()
            
            elif choice == '3':
                self.list_todos()
                try:
                    todo_id = int(input("请输入要完成的任务ID: ").strip())
                    self.complete_todo(todo_id)
                except ValueError:
                    print("✗ 请输入有效的数字ID")
            
            elif choice == '4':
                self.list_todos()
                try:
                    todo_id = int(input("请输入要删除的任务ID: ").strip())
                    self.delete_todo(todo_id)
                except ValueError:
                    print("✗ 请输入有效的数字ID")
            
            elif choice == '5':
                print("\n👋 再见！")
                break
            
            else:
                print("✗ 无效的选项，请重新选择")


if __name__ == '__main__':
    app = TodoApp()
    app.run()
