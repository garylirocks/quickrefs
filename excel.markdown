# Excel

- [Input](#input)
- [Functions / Scripting](#functions--scripting) - [Referencing](#referencing) - [`&`](#) - [`LEFT`](#left)
- [Shortcuts](#shortcuts)

## Input

- 默认情况下： 文本靠左显示，数值靠右显示;
- 按住`ctrl`键时的自动填充不会填充序列，只会做复制;
- `ctrl+d` 复制上一单元格的内容到当前单元格;

## Functions / Scripting

### Referencing

- `A1` 相对引用
- `$A$1` `$A1` `A$1` 绝对引用
- `(B4:K6 D1:F8)` 取交集
- `A1:B5, H:J` 取并集
- `[Book]Sheet!A2:B4` [工作薄]工作表!起始单元格:终止单元格

### `&`

Join strings

```excel
=A1&B1
```

### `LEFT`

```excel
=LEFT(A1, FIND(" ", A1&""))
```

Get the first word in `A1`

## Shortcuts

- 【跳转】

      	* `ctrl + 1`    设置格式
      	* `ctrl + arrow` 快速跳转到行、列的首末单元格

- 【输入】

      	* `ctrl + enter`  给当前选中单元格赋同样的值
      	* `alt + down`  当前列数值的下拉列表
      	* `ctrl + ;`  当前日期
      	* `ctrl + shift + ;` 当前时间
      	* **将公式作为数组公式输入** 从公式单元格开始，选择要包含数组公式的区域, 按 F2，然后按 Ctrl+Shift+Enter

- 【公式】

      	* `F4`  切换绝对、相对引用
      	* `F9` 公式结果
      	* <code>ctrl + `</code> 显示公式
