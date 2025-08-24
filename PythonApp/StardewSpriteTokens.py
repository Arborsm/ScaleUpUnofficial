import json
import sys
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from typing import List, Dict, Optional, Tuple, Any

import pywinstyles
import sv_ttk
from PIL import Image, ImageTk

# 类型别名 (Type Aliases)
RectDict = Dict[str, int]
ScaleDict = Dict[str, float]
OriginDict = Dict[str, float]
DestinationDict = Dict[str, Any]


# ==============================================================================
# 1. C#核心逻辑对应的数据类
# ==============================================================================
class SpriteData:
    """一个数据类, 用于存储与精灵图渲染相关的各种参数。"""

    def __init__(self) -> None:
        self.sprite_origin_x: Optional[int] = None
        self.sprite_origin_y: Optional[int] = None
        self.breath_type: Optional[int] = None
        self.chest_source_x: Optional[int] = None
        self.chest_source_y: Optional[int] = None
        self.chest_source_width: Optional[int] = None
        self.chest_source_height: Optional[int] = None
        self.chest_adjust_x: Optional[int] = None
        self.chest_adjust_y: Optional[int] = None
        self.head_shot_x: Optional[int] = None
        self.head_shot_y: Optional[int] = None
        self.head_shot_x_render_offset: Optional[int] = None
        self.head_shot_y_render_offset: Optional[int] = None
        self.mini_map_x_offset: Optional[int] = None
        self.mini_map_y_offset: Optional[int] = None


# ==============================================================================
# 2. Tkinter 可视化编辑器
# ==============================================================================
class SpriteEditorApp:
    """用于编辑星露谷风格精灵图属性的Tkinter图形界面应用。"""
    # --- 类常量定义 ---
    SLICE_WIDTH, SLICE_HEIGHT = 64, 128
    HANDLE_SIZE, RULER_SPACE = 8, 40
    ASPECT_RATIO = 16 / 24

    COLOR_BG = "#ffffff"
    COLOR_CANVAS_BG = "#f0f0f0"
    COLOR_ACCENT = "#0078d4"
    COLOR_BREATHING_BOX = "#ff8c00"  # Orange
    COLOR_CENTERLINE = "#e81123"  # Red
    COLOR_TEXT = "#202020"
    COLOR_TEXT_DIM = "#707070"

    def __init__(self, master: tk.Tk) -> None:
        self.root = master
        self.root.title("Stardew Sprite Tokens")
        self.root.geometry("1600x900")
        self.root.minsize(1280, 720)
        self.root.configure(bg=self.COLOR_BG)
        self.center_window()

        # --- 实例变量初始化 ---
        self.slices: List[Image.Image] = []
        self.preview_photos: List[ImageTk.PhotoImage] = []
        self.current_slice_index: int = 0
        self.selection_coords: RectDict = {"x": 12, "y": 58, "width": 40, "height": 60}
        self.slice_display_offset: Dict[str, float] = {"x": 0, "y": 0}
        self.display_scale: float = 1.0
        self.scaled_slice_photo: Optional[ImageTk.PhotoImage] = None
        self.active_handle: Optional[str] = None
        self.drag_start_pos: Optional[Tuple[int, int]] = None
        self.drag_original_coords: Optional[RectDict] = None
        self.vars: Dict[str, tk.StringVar] = {}
        self._is_updating_programmatically: bool = False

        # --- UI 控件变量 ---
        self.left_panel: Optional[ttk.Frame] = None
        self.right_panel: Optional[ttk.Frame] = None
        self.canvas: Optional[tk.Canvas] = None
        self.preview1_canvas: Optional[tk.Canvas] = None
        self.preview2_canvas: Optional[tk.Canvas] = None
        self.slice_combo: Optional[ttk.Combobox] = None
        self.export_button: Optional[ttk.Button] = None
        self.export_defaults_var = tk.BooleanVar(value=True)
        self.show_centerlines_var = tk.BooleanVar(value=True)

        # --- 初始化流程 ---
        self.setup_styles()
        self.create_layout()
        self.create_controls()
        self.bind_events()
        self.set_initial_defaults()
        self.selection_coords = self.center_and_apply_aspect_ratio(self.selection_coords)
        self.full_redraw()

    def setup_styles(self) -> None:
        """配置ttk组件的样式。"""
        style = ttk.Style()
        style.configure("TFrame", background=self.COLOR_BG)
        style.configure("TLabel", background=self.COLOR_BG, foreground=self.COLOR_TEXT)
        style.configure("TLabelframe", background=self.COLOR_BG)
        style.configure("TLabelframe.Label", background=self.COLOR_BG, foreground=self.COLOR_TEXT)
        style.configure("Accent.TButton", font=("Segoe UI Semibold", 10))
        style.configure("Toast.TLabel", background="#323232", foreground="white", padding=10, font=("Segoe UI", 10))
        style.configure("TSwitch", background=self.COLOR_BG)
        style.configure("Switch.TCheckbutton", background=self.COLOR_BG)
        style.configure(
            "Readonly.TLabel",
            background=self.COLOR_CANVAS_BG,
            foreground=self.COLOR_TEXT_DIM,
            padding=(5, 3),
            borderwidth=1,
            relief=tk.SUNKEN
        )

    def create_layout(self) -> None:
        """创建应用的主布局框架。"""
        self.root.grid_columnconfigure(1, weight=1)
        self.root.grid_rowconfigure(0, weight=1)

        left_panel = ttk.Frame(self.root, padding=15, width=300)  # 给左侧面板一个初始宽度
        left_panel.grid(row=0, column=0, sticky="ns", padx=(10, 0))
        left_panel.grid_propagate(False)  # 防止面板收缩

        center_panel = ttk.Frame(self.root, padding=(10, 10, 10, 10))
        center_panel.grid(row=0, column=1, sticky="nsew")

        self.canvas = tk.Canvas(center_panel, bg=self.COLOR_CANVAS_BG, highlightthickness=0)
        self.canvas.pack(fill=tk.BOTH, expand=True)

        right_panel = ttk.Frame(self.root, width=380, padding=15)
        right_panel.grid(row=0, column=2, sticky="ns", padx=(0, 10))
        right_panel.grid_rowconfigure(0, weight=1)
        right_panel.grid_rowconfigure(1, weight=1)
        right_panel.grid_propagate(False)

        self.left_panel = left_panel
        self.right_panel = right_panel

    def create_controls(self) -> None:
        """在布局框架中创建所有的UI控件。"""
        # --- 左侧面板 ---
        self._create_left_panel_controls()

        # --- 右侧面板 ---
        preview1_frame = ttk.Labelframe(self.right_panel, text="Character Preview", padding=10)
        preview1_frame.grid(row=0, column=0, sticky="nsew", pady=(0, 10))
        self.preview1_canvas = tk.Canvas(preview1_frame, bg=self.COLOR_BG, highlightthickness=0)
        self.preview1_canvas.pack(fill='both', expand=True)

        preview2_frame = ttk.Labelframe(self.right_panel, text="Map Icon Preview", padding=10)
        preview2_frame.grid(row=1, column=0, sticky="nsew", pady=(0, 10))
        self.preview2_canvas = tk.Canvas(preview2_frame, bg=self.COLOR_BG, highlightthickness=0)
        self.preview2_canvas.pack(fill='both', expand=True)

    def _create_left_panel_controls(self) -> None:
        """创建左侧面板的所有控件。"""
        # 1. Source Image Frame
        source_frame = ttk.Labelframe(self.left_panel, text="Source Image", padding=10)
        source_frame.pack(fill='x', pady=(0, 10))
        ttk.Button(source_frame, text="Load Spritesheet...", command=self.open_texture, style="Accent.TButton").pack(
            fill='x', pady=5)
        self.slice_combo = ttk.Combobox(source_frame, state='disabled')
        self.slice_combo.pack(fill='x', expand=True, pady=5)

        # 2. Settings Notebook (Tabs)
        notebook = ttk.Notebook(self.left_panel)
        notebook.pack(fill="x", expand=False, pady=(5, 15))

        # -- Tab 1: Main Settings --
        main_tab = ttk.Frame(notebook, padding=10)
        notebook.add(main_tab, text="Main Settings")
        self._create_main_settings_tab(main_tab)

        # -- Tab 2: Animation --
        anim_tab = ttk.Frame(notebook, padding=10)
        notebook.add(anim_tab, text="Animation")
        self._create_animation_tab(anim_tab)

        # -- Tab 3: Offsets --
        offset_tab = ttk.Frame(notebook, padding=10)
        notebook.add(offset_tab, text="Offsets")
        self._create_offset_tab(offset_tab)

        # 3. Options Panel
        options_frame = ttk.Frame(self.left_panel)
        options_frame.pack(fill='x', pady=(0, 10))
        options_frame.grid_columnconfigure((0, 1), weight=1)

        # Checkbutton: Show Centerlines
        centerline_switch = ttk.Checkbutton(
            options_frame, text="Show Centerlines", variable=self.show_centerlines_var, command=self.full_redraw,
            style="Switch.TCheckbutton")
        centerline_switch.grid(row=0, column=0, sticky='w', padx=5)

        # Checkbutton: Include Defaults
        export_switch = ttk.Checkbutton(
            options_frame, text="Include Defaults", variable=self.export_defaults_var, style="Switch.TCheckbutton")
        export_switch.grid(row=0, column=1, sticky='w', padx=5)

        # 4. Spacer to push export button to the bottom
        ttk.Frame(self.left_panel).pack(fill='y', expand=True)
        ttk.Separator(self.left_panel).pack(fill='x', pady=5)

        # 5. Export Button
        self.export_button = ttk.Button(
            self.left_panel, text="Export JSON to Clipboard", command=self.export_to_json, style="Accent.TButton")
        self.export_button.pack(fill='x', expand=False, ipady=4, pady=(5, 0))

    def _create_control_row(self, parent: ttk.Frame, name: str, row_idx: int, trace_func: callable,
                            is_readonly: bool = False):
        """辅助函数, 用于创建一行标签和输入控件。"""
        ttk.Label(parent, text=name).grid(row=row_idx, column=0, sticky="w", pady=4, padx=(0, 10))
        var = tk.StringVar(value="0")
        self.vars[name] = var
        if is_readonly:
            widget = ttk.Label(parent, textvariable=var, style="Readonly.TLabel", anchor="w")
        else:
            widget = ttk.Entry(parent, textvariable=var)
            var.trace_add("write", trace_func)
        widget.grid(row=row_idx, column=1, sticky="ew")

    def _create_main_settings_tab(self, parent: ttk.Frame):
        """填充 "Main Settings" 选项卡。"""
        parent.grid_columnconfigure(1, weight=1)
        # Headshot Editable
        headshot_frame = ttk.Labelframe(parent, text="Headshot Coordinates", padding=10)
        headshot_frame.pack(fill='x', pady=(0, 10))
        headshot_frame.grid_columnconfigure(1, weight=1)
        self._create_control_row(headshot_frame, "HeadShotX", 0, self.on_headshot_change)
        self._create_control_row(headshot_frame, "HeadShotY", 1, self.on_headshot_change)

        # Game Render Readonly
        render_frame = ttk.Labelframe(parent, text="Game Render Properties", padding=10)
        render_frame.pack(fill='x')
        render_frame.grid_columnconfigure(1, weight=1)
        self._create_control_row(render_frame, "SpriteOriginX", 0, lambda *a: None, is_readonly=True)
        self._create_control_row(render_frame, "SpriteOriginY", 1, lambda *a: None, is_readonly=True)
        self._create_control_row(render_frame, "HeadShotXRenderOffset", 2, lambda *a: None, is_readonly=True)
        self._create_control_row(render_frame, "HeadShotYRenderOffset", 3, lambda *a: None, is_readonly=True)

    def _create_animation_tab(self, parent: ttk.Frame):
        """填充 "Animation" 选项卡。"""
        parent.grid_columnconfigure(1, weight=1)
        # Breath Type
        ttk.Label(parent, text="BreathType").grid(row=0, column=0, sticky="w", pady=4, padx=(0, 10))
        var = tk.StringVar()
        self.vars["BreathType"] = var
        combo = ttk.Combobox(parent, textvariable=var, values=["0: None", "1: Male", "2: Female"], state='readonly')
        var.trace_add("write", self.on_breath_type_change)
        combo.grid(row=0, column=1, sticky="ew", pady=(0, 10))

        # Chest Source Editable
        chest_frame = ttk.Labelframe(parent, text="Chest Source", padding=10)
        chest_frame.grid(row=1, column=0, columnspan=2, sticky='ew', pady=(0, 10))
        chest_frame.grid_columnconfigure(1, weight=1)
        self._create_control_row(chest_frame, "ChestSourceX", 0, self.on_param_change)
        self._create_control_row(chest_frame, "ChestSourceY", 1, self.on_param_change)
        self._create_control_row(chest_frame, "ChestSourceWidth", 2, self.on_param_change)
        self._create_control_row(chest_frame, "ChestSourceHeight", 3, self.on_param_change)

        # Chest Adjust Readonly
        adjust_frame = ttk.Labelframe(parent, text="Chest Adjust", padding=10)
        adjust_frame.grid(row=2, column=0, columnspan=2, sticky='ew')
        adjust_frame.grid_columnconfigure(1, weight=1)
        self._create_control_row(adjust_frame, "ChestAdjustX", 0, lambda *a: None, is_readonly=True)
        self._create_control_row(adjust_frame, "ChestAdjustY", 1, lambda *a: None, is_readonly=True)

    def _create_offset_tab(self, parent: ttk.Frame):
        """填充 "Offsets" 选项卡。"""
        parent.grid_columnconfigure(1, weight=1)
        # MiniMap Editable
        minimap_frame = ttk.Labelframe(parent, text="Minimap Icon Offset", padding=10)
        minimap_frame.pack(fill='x', pady=(0, 10))
        minimap_frame.grid_columnconfigure(1, weight=1)
        self._create_control_row(minimap_frame, "MiniMapXOffset", 0, self.on_param_change)
        self._create_control_row(minimap_frame, "MiniMapYOffset", 1, self.on_param_change)

    def bind_events(self) -> None:
        """绑定所有UI事件。"""
        self.canvas.bind("<Configure>", lambda _: self.full_redraw())
        self.canvas.bind("<ButtonPress-1>", self.on_mouse_press)
        self.canvas.bind("<B1-Motion>", self.on_mouse_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_mouse_release)
        self.canvas.bind("<Motion>", self.update_cursor)
        self.slice_combo.bind('<<ComboboxSelected>>', self.on_slice_selected)
        self.preview1_canvas.bind("<Configure>", lambda _: self.redraw_previews())
        self.preview2_canvas.bind("<Configure>", lambda _: self.redraw_previews())

    def on_breath_type_change(self, *args: Any) -> None:
        """当呼吸类型改变时, 应用默认值并重绘。"""
        if self._is_updating_programmatically:
            return
        try:
            breath_type_val = int(self.vars['BreathType'].get()[0])
            self._is_updating_programmatically = True
            self.apply_defaults_for_breath_type(breath_type_val)
            self._is_updating_programmatically = False
            self.redraw_source_and_previews()
        except (ValueError, IndexError):
            # 忽略解析错误
            pass
        finally:
            self._is_updating_programmatically = False

    def on_headshot_change(self, *args: Any) -> None:
        """当头像坐标输入框改变时, 更新画布上的选框。"""
        if self._is_updating_programmatically:
            return
        try:
            headshot_x = int(self.vars['HeadShotX'].get())
            headshot_y = int(self.vars['HeadShotY'].get())
            width = self.SLICE_WIDTH - 2 * headshot_x
            height = int(width / self.ASPECT_RATIO)
            # 使用临时字典进行计算
            temp_coords = {"x": headshot_x, "y": headshot_y, "width": width, "height": height}
            # 调用中心化和应用比例的函数来确保坐标正确
            self.selection_coords = self.center_and_apply_aspect_ratio(temp_coords)
            self.redraw_selection_and_previews()
        except (ValueError, tk.TclError):
            # 忽略因输入不完整（如“ - ”）导致的错误
            pass

    def update_headshot_from_selection(self) -> None:
        """当画布上的选框改变时, 更新头像坐标输入框的值。"""
        if self._is_updating_programmatically:
            return
        self._is_updating_programmatically = True
        try:
            self.vars['HeadShotX'].set(str(self.selection_coords['x']))
            self.vars['HeadShotY'].set(str(self.selection_coords['y']))
        finally:
            self._is_updating_programmatically = False

    def center_window(self) -> None:
        """将主窗口居中于屏幕。"""
        self.root.update_idletasks()
        w, h = self.root.winfo_width(), self.root.winfo_height()
        sw, sh = self.root.winfo_screenwidth(), self.root.winfo_screenheight()
        x, y = (sw // 2) - (w // 2), (sh // 2) - (h // 2)
        self.root.geometry(f'{w}x{h}+{x}+{y}')

    def on_param_change(self, *args: Any) -> None:
        """当高级参数输入框改变时, 重绘预览。"""
        if self._is_updating_programmatically:
            return
        keys_to_check = ['ChestSourceX', 'ChestSourceY', 'ChestSourceWidth', 'ChestSourceHeight']
        if any(self.vars[key].get() in ('', '-') for key in keys_to_check if key in self.vars):
            return
        self.redraw_source_and_previews()

    def set_initial_defaults(self) -> None:
        """设置UI控件的初始默认值。"""
        self.vars['BreathType'].set("0: None")
        for attr in ['SpriteOriginX', 'SpriteOriginY', 'HeadShotXRenderOffset', 'HeadShotYRenderOffset',
                     'MiniMapXOffset', 'MiniMapYOffset', 'ChestAdjustX', 'ChestAdjustY']:
            if attr in self.vars:
                self.vars[attr].set("0")
        self.apply_defaults_for_breath_type(0)

    def on_slice_selected(self, _: tk.Event) -> None:
        """当从下拉框选择新的切片时, 触发完全重绘。"""
        self.current_slice_index = self.slice_combo.current()
        self.full_redraw()

    def on_mouse_press(self, event: tk.Event) -> None:
        """处理画布上的鼠标按下事件。"""
        self.active_handle = self.get_handle_at(event.x, event.y)
        if self.active_handle:
            self.drag_start_pos = (event.x, event.y)
            self.drag_original_coords = self.selection_coords.copy()

    def on_mouse_drag(self, event: tk.Event) -> None:
        """处理画布上的鼠标拖动事件, 用于调整选框。"""
        if not all([self.active_handle, self.drag_start_pos, self.drag_original_coords]):
            return

        total_dy = (event.y - self.drag_start_pos[1]) / self.display_scale
        r: Dict[str, float] = self.drag_original_coords.copy()
        center_y = self.drag_original_coords['y'] + self.drag_original_coords['height'] / 2

        if self.active_handle == 'body':
            r['y'] += total_dy
        else:
            delta_h = total_dy * 2 * (1 if 's' in self.active_handle else -1)
            r['height'] += delta_h
            r['y'] = center_y - r['height'] / 2

        self.selection_coords = self.center_and_apply_aspect_ratio(r)
        self.redraw_selection_and_previews()

    def on_mouse_release(self, _: tk.Event) -> None:
        """处理画布上的鼠标释放事件。"""
        self.active_handle = None
        self.drag_original_coords = None
        self.update_headshot_from_selection()

    def center_and_apply_aspect_ratio(self, rect: Dict[str, float]) -> RectDict:
        """根据给定的矩形, 居中并应用宽高比, 最后返回一个整数矩形。"""
        r = rect.copy()
        if 'width' in r and 'height' in r and r['width'] > 0 and r['height'] > 0:
            if self.active_handle and ('w' in self.active_handle or 'e' in self.active_handle):
                # 宽度驱动高度
                r['height'] = r['width'] / self.ASPECT_RATIO
            else:
                # 高度驱动宽度 (默认行为)
                r['width'] = r['height'] * self.ASPECT_RATIO

        r['height'] = max(2, r.get('height', 2))
        r['width'] = max(2, r.get('width', 2))
        r['x'] = (self.SLICE_WIDTH - r['width']) / 2
        r['y'] = max(0, min(r.get('y', 0), self.SLICE_HEIGHT - r['height']))

        # 返回所有值都为整数的新字典
        return {k: int(v) for k, v in r.items()}

    def open_texture(self) -> None:
        """打开文件对话框以加载精灵图工作表。"""
        path = filedialog.askopenfilename(filetypes=[("Image Files", "*.png;*.jpg;*.jpeg")])
        if not path:
            return
        try:
            with Image.open(path) as texture:
                texture = texture.convert("RGBA")
                self.slices = []
                for y in range(0, texture.height, self.SLICE_HEIGHT):
                    for x in range(0, texture.width, self.SLICE_WIDTH):
                        self.slices.append(texture.crop((x, y, x + self.SLICE_WIDTH, y + self.SLICE_HEIGHT)))

            self.slice_combo['values'] = [f"Slice {i}" for i in range(len(self.slices))]
            if self.slices:
                self.slice_combo.current(0)
                self.current_slice_index = 0

            self.slice_combo.config(state='readonly')
            self.full_redraw()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load image file:\n{e}")

    def full_redraw(self) -> None:
        """执行一次完整的界面重绘。"""
        self.canvas.delete("all")
        if not self.slices:
            if self.canvas.winfo_width() > 1:
                self.canvas.create_text(
                    self.canvas.winfo_width() / 2, self.canvas.winfo_height() / 2,
                    text="Load a spritesheet to begin", fill=self.COLOR_TEXT, font=("Segoe UI", 12))
            return
        self.draw_source_slice_background()
        self.redraw_selection_and_previews()

    def redraw_selection_and_previews(self) -> None:
        """重绘选框和所有预览。"""
        self.update_headshot_from_selection()
        self.redraw_source_and_previews()

    def redraw_source_and_previews(self) -> None:
        """重绘源图像上的前景（选框等）和所有预览。"""
        self.canvas.delete("source_fg_items")
        self.draw_source_slice_foreground()
        self.redraw_previews()

    def redraw_previews(self) -> None:
        """仅重绘右侧的预览面板。"""
        if not self.preview1_canvas or not self.preview2_canvas:
            return
        self.preview1_canvas.delete("all")
        self.preview2_canvas.delete("all")
        if self.slices:
            self.draw_all_previews()

    def draw_source_slice_background(self) -> None:
        """在主画布上绘制源切片的背景图像和标尺。"""
        canvas_w, canvas_h = self.canvas.winfo_width(), self.canvas.winfo_height()
        available_w, available_h = canvas_w - self.RULER_SPACE * 2, canvas_h - self.RULER_SPACE * 2
        if available_w < 1 or available_h < 1:
            return

        self.display_scale = min(available_w / self.SLICE_WIDTH, available_h / self.SLICE_HEIGHT)
        display_w = int(self.SLICE_WIDTH * self.display_scale)
        display_h = int(self.SLICE_HEIGHT * self.display_scale)

        resized_slice = self.slices[self.current_slice_index].resize((display_w, display_h), Image.Resampling.NEAREST)
        self.scaled_slice_photo = ImageTk.PhotoImage(resized_slice)

        self.slice_display_offset['x'] = (canvas_w - display_w) / 2
        self.slice_display_offset['y'] = (canvas_h - display_h) / 2

        self.canvas.create_image(self.slice_display_offset['x'], self.slice_display_offset['y'], anchor="nw",
                                 image=self.scaled_slice_photo)
        self.draw_rulers()

    def draw_source_slice_foreground(self) -> None:
        """在主画布上绘制选框、控制手柄、呼吸区域框和中心线。"""
        r = self.selection_coords
        off_x, off_y = self.slice_display_offset['x'], self.slice_display_offset['y']
        scale = self.display_scale

        # 选框
        cx, cy = off_x + r['x'] * scale, off_y + r['y'] * scale
        cw, ch = r['width'] * scale, r['height'] * scale
        self.canvas.create_rectangle(cx, cy, cx + cw, cy + ch, outline=self.COLOR_ACCENT, width=2,
                                     tags="source_fg_items")
        self.draw_handles(cx, cy, cw, ch)

        # 呼吸框
        sd = self.collect_sprite_data()
        if sd.breath_type and sd.breath_type > 0:
            try:
                bx, by = int(self.vars['ChestSourceX'].get()), int(self.vars['ChestSourceY'].get())
                bw, bh = int(self.vars['ChestSourceWidth'].get()), int(self.vars['ChestSourceHeight'].get())
                bcx, bcy = off_x + bx * scale, off_y + by * scale
                bcw, bch = bw * scale, bh * scale
                self.canvas.create_rectangle(bcx, bcy, bcx + bcw, bch + bcy, outline=self.COLOR_BREATHING_BOX, width=2,
                                             dash=(4, 4), tags="source_fg_items")
            except (ValueError, tk.TclError):
                pass  # Ignore if values are not valid ints yet

        # 中心线
        if self.show_centerlines_var.get():
            center_x = off_x + (self.SLICE_WIDTH / 2) * scale
            center_y = off_y + (self.SLICE_HEIGHT / 2) * scale
            display_h = self.SLICE_HEIGHT * scale
            display_w = self.SLICE_WIDTH * scale
            self.canvas.create_line(off_x, center_y, off_x + display_w, center_y, fill=self.COLOR_CENTERLINE,
                                     dash=(4, 4), tags="source_fg_items")
            self.canvas.create_line(center_x, off_y, center_x, off_y + display_h, fill=self.COLOR_CENTERLINE,
                                     dash=(4, 4), tags="source_fg_items")

    def draw_handles(self, x: float, y: float, w: float, h: float) -> None:
        """在选框边缘绘制控制手柄。"""
        hs = self.HANDLE_SIZE
        coords = [
            (x + w / 2, y), (x, y + h / 2),
            (x + w, y + h / 2), (x + w / 2, y + h)
        ]
        for cx, cy in coords:
            self.canvas.create_rectangle(cx - hs / 2, cy - hs / 2, cx + hs / 2, cy + hs / 2, fill=self.COLOR_ACCENT,
                                         outline=self.COLOR_BG, width=1, tags="source_fg_items")

    def draw_all_previews(self) -> None:
        """绘制所有预览图像（角色和地图图标）。"""
        sd = self.collect_sprite_data()
        self.preview_photos.clear()
        sel = self.selection_coords

        # 绘制角色和胸部预览
        self.draw_character_and_chest_preview(sd, sel)

        # 绘制地图图标预览
        side_length = 32
        mini_map_x_off = sd.mini_map_x_offset or 0
        mini_map_y_off = sd.mini_map_y_offset or 0

        crop_rect_square = {
            'x': 14 + mini_map_x_off, 'y': 70 + mini_map_y_off, 'width': side_length, 'height': side_length
        }

        p_canvas = self.preview2_canvas
        map_display_size = int(min(p_canvas.winfo_width(), p_canvas.winfo_height()) * 0.9)
        map_up_dest: DestinationDict = {'width': map_display_size, 'height': map_display_size}
        self.draw_single_preview(p_canvas, crop_rect_square, map_up_dest)

    def draw_character_and_chest_preview(self, sd: SpriteData, sel: RectDict) -> None:
        """在预览面板1中绘制角色和胸部呼吸动画部分。"""
        target_canvas = self.preview1_canvas
        if target_canvas.winfo_width() <= 1 or not self.slices or sel['width'] <= 0:
            return

        canvas_w, canvas_h = target_canvas.winfo_width(), target_canvas.winfo_height()
        preview_scale = min(canvas_w / sel['width'], canvas_h / sel['height']) * 0.95
        dest_w, dest_h = int(sel['width'] * preview_scale), int(sel['height'] * preview_scale)

        bg_photo = self.get_resized_photo(sel, (dest_w, dest_h))
        if not bg_photo:
            return

        bg_x = (canvas_w - dest_w) / 2
        bg_y = (canvas_h - dest_h) / 2
        target_canvas.create_image(bg_x, bg_y, anchor="nw", image=bg_photo)
        self.preview_photos.append(bg_photo)

        if sd.breath_type and sd.breath_type > 0:
            try:
                cax, cay = (0, 0) if sd.breath_type == 1 else (0, -4)
                csx, csy = int(self.vars['ChestSourceX'].get()), int(self.vars['ChestSourceY'].get())
                csw, csh = int(self.vars['ChestSourceWidth'].get()), int(self.vars['ChestSourceHeight'].get())

                relative_x_in_slice = cax - sel['x']
                relative_y_in_slice = cay - sel['y']
                chest_draw_x = bg_x + (relative_x_in_slice * preview_scale)
                chest_draw_y = bg_y + (relative_y_in_slice * preview_scale)

                chest_dest_w, chest_dest_h = int(csw * preview_scale), int(csh * preview_scale)
                chest_rect = {'x': csx, 'y': csy, 'width': csw, 'height': csh}
                chest_photo = self.get_resized_photo(chest_rect, (chest_dest_w, chest_dest_h))

                if chest_photo:
                    target_canvas.create_image(chest_draw_x, chest_draw_y, anchor="nw", image=chest_photo)
                    self.preview_photos.append(chest_photo)
            except (ValueError, tk.TclError):
                pass  # Ignore if values are not valid ints yet

        if self.show_centerlines_var.get():
            target_canvas.create_line(0, canvas_h / 2, canvas_w, canvas_h / 2, fill=self.COLOR_CENTERLINE, dash=(4, 4))
            target_canvas.create_line(canvas_w / 2, 0, canvas_w / 2, canvas_h, fill=self.COLOR_CENTERLINE, dash=(4, 4))

    def get_resized_photo(self, crop_rect: RectDict, dest_size: Tuple[int, int]) -> Optional[ImageTk.PhotoImage]:
        """从当前切片裁剪、缩放并返回一个PhotoImage对象。"""
        try:
            clamped = {
                'x': max(0, crop_rect['x']),
                'y': max(0, crop_rect['y']),
                'width': crop_rect['width'],
                'height': crop_rect['height']
            }
            clamped['width'] = min(clamped['width'], self.SLICE_WIDTH - clamped['x'])
            clamped['height'] = min(clamped['height'], self.SLICE_HEIGHT - clamped['y'])

            if clamped['width'] <= 0 or clamped['height'] <= 0 or dest_size[0] <= 0 or dest_size[1] <= 0:
                return None

            region = self.slices[self.current_slice_index].crop((
                clamped['x'], clamped['y'], clamped['x'] + clamped['width'], clamped['y'] + clamped['height']
            ))
            resized = region.resize(dest_size, Image.Resampling.NEAREST)
            return ImageTk.PhotoImage(resized)
        except (ValueError, IndexError, TypeError) as e:
            # 捕获更具体的错误
            print(f"Error creating PhotoImage: {e}")
            return None

    def draw_single_preview(self, target_canvas: tk.Canvas, crop_rect: RectDict,
                            up_dest: Optional[DestinationDict]) -> None:
        """在指定的画布上绘制单个预览图像。"""
        if not (up_dest and up_dest['width'] > 0 and target_canvas.winfo_width() > 1):
            return

        canvas_w, canvas_h = target_canvas.winfo_width(), target_canvas.winfo_height()
        photo = self.get_resized_photo(crop_rect, (int(up_dest['width']), int(up_dest['height'])))
        if photo:
            center_x, center_y = canvas_w / 2, canvas_h / 2
            final_x = center_x - up_dest['width'] / 2 + up_dest.get('x', 0)
            final_y = center_y - up_dest['height'] / 2 + up_dest.get('y', 0)
            target_canvas.create_image(final_x, final_y, anchor="nw", image=photo)
            self.preview_photos.append(photo)
        else:
            center_x, center_y = canvas_w / 2, canvas_h / 2
            target_canvas.create_text(center_x, center_y, text="Render Error", fill="red", width=150)

        if self.show_centerlines_var.get():
            target_canvas.create_line(0, canvas_h / 2, canvas_w, canvas_h / 2, fill=self.COLOR_CENTERLINE, dash=(4, 4))
            target_canvas.create_line(canvas_w / 2, 0, canvas_w / 2, canvas_h, fill=self.COLOR_CENTERLINE, dash=(4, 4))

    def collect_sprite_data(self) -> SpriteData:
        """从UI控件收集数据并填充SpriteData对象。"""
        sd = SpriteData()
        # 将UI中的驼峰命名转换为snake_case以匹配SpriteData属性
        name_map = {
            "SpriteOriginX": "sprite_origin_x", "SpriteOriginY": "sprite_origin_y",
            "BreathType": "breath_type", "ChestSourceX": "chest_source_x",
            "ChestSourceY": "chest_source_y", "ChestSourceWidth": "chest_source_width",
            "ChestSourceHeight": "chest_source_height", "ChestAdjustX": "chest_adjust_x",
            "ChestAdjustY": "chest_adjust_y", "HeadShotX": "head_shot_x",
            "HeadShotY": "head_shot_y", "HeadShotXRenderOffset": "head_shot_x_render_offset",
            "HeadShotYRenderOffset": "head_shot_y_render_offset", "MiniMapXOffset": "mini_map_x_offset",
            "MiniMapYOffset": "mini_map_y_offset"
        }
        for ui_name, var in self.vars.items():
            attr_name = name_map.get(ui_name)
            if not attr_name:
                continue

            val_str = var.get()
            if ui_name == "BreathType":
                value = int(val_str[0]) if val_str and val_str[0].isdigit() else 0
            else:
                try:
                    value = int(val_str)
                except (ValueError, TypeError):
                    value = None
            setattr(sd, attr_name, value)
        return sd

    def get_handle_at(self, cx: int, cy: int) -> Optional[str]:
        """根据画布坐标返回鼠标下的控制手柄或'body'。"""
        if self.display_scale == 0:
            return None
        sx, sy = self.canvas_to_slice_coords(cx, cy)
        r = self.selection_coords
        hs = (self.HANDLE_SIZE / self.display_scale) / 2

        if r['x'] + r['width'] / 2 - hs <= sx <= r['x'] + r['width'] / 2 + hs:
            if r['y'] - hs <= sy <= r['y'] + hs: return 'n'
            if r['y'] + r['height'] - hs <= sy <= r['y'] + r['height'] + hs: return 's'
        if r['y'] + r['height'] / 2 - hs <= sy <= r['y'] + r['height'] / 2 + hs:
            if r['x'] - hs <= sx <= r['x'] + hs: return 'w'
            if r['x'] + r['width'] - hs <= sx <= r['x'] + r['width'] + hs: return 'e'
        if r['x'] <= sx <= r['x'] + r['width'] and r['y'] <= sy <= r['y'] + r['height']:
            return 'body'
        return None

    def canvas_to_slice_coords(self, cx: int, cy: int) -> Tuple[float, float]:
        """将画布坐标转换为切片内的本地坐标。"""
        if self.display_scale == 0:
            return 0.0, 0.0
        return (
            (cx - self.slice_display_offset['x']) / self.display_scale,
            (cy - self.slice_display_offset['y']) / self.display_scale
        )

    def update_cursor(self, event: tk.Event) -> None:
        """根据鼠标位置更新光标样式。"""
        handle = self.get_handle_at(event.x, event.y)
        cursors = {
            'n': 'sb_v_double_arrow', 's': 'sb_v_double_arrow',
            'w': 'sb_h_double_arrow', 'e': 'sb_h_double_arrow',
            'body': 'fleur'
        }
        self.canvas.config(cursor=cursors.get(handle, ''))

    def draw_rulers(self) -> None:
        """在主画布周围绘制标尺。"""
        off_x, off_y = self.slice_display_offset['x'], self.slice_display_offset['y']
        scale, color = self.display_scale, self.COLOR_TEXT_DIM
        # 水平标尺
        for i in range(0, self.SLICE_WIDTH + 1, 8):
            px = off_x + i * scale
            self.canvas.create_line(px, off_y - 10, px, off_y - 5, fill=color)
            if i % 16 == 0:
                self.canvas.create_text(px, off_y - 15, text=str(i), fill=color, font=("Segoe UI", 8))
        # 垂直标尺
        for i in range(0, self.SLICE_HEIGHT + 1, 8):
            py = off_y + i * scale
            self.canvas.create_line(off_x - 10, py, off_x - 5, py, fill=color)
            if i % 16 == 0:
                self.canvas.create_text(off_x - 15, py, text=str(i), fill=color, anchor='e', font=("Segoe UI", 8))

    def apply_defaults_for_breath_type(self, breath_type: int) -> None:
        """根据选择的呼吸类型应用一组默认值。"""
        defaults_map_list = [
            {'ChestSourceX': 0, 'ChestSourceY': 0, 'ChestSourceWidth': 0, 'ChestSourceHeight': 0, 'ChestAdjustX': 0,
             'ChestAdjustY': 0},
            {'ChestSourceX': 24, 'ChestSourceY': 98, 'ChestSourceWidth': 16, 'ChestSourceHeight': 16,
             'ChestAdjustX': 0, 'ChestAdjustY': 0},
            {'ChestSourceX': 24, 'ChestSourceY': 100, 'ChestSourceWidth': 16, 'ChestSourceHeight': 8,
             'ChestAdjustX': 0, 'ChestAdjustY': -4}
        ]
        if 0 <= breath_type < len(defaults_map_list):
            defaults = defaults_map_list[breath_type]
            for attr, value in defaults.items():
                if attr in self.vars:
                    self.vars[attr].set(str(value))

    def export_to_json(self) -> None:
        """收集数据, 生成JSON字符串, 并复制到剪贴板。"""
        sd = self.collect_sprite_data()
        include_defaults = self.export_defaults_var.get()

        defaults_map = {
            'Male': {'chest_source_x': 24, 'chest_source_y': 98, 'chest_source_width': 16,
                     'chest_source_height': 16},
            'Female': {'chest_source_x': 24, 'chest_source_y': 100, 'chest_source_width': 16,
                       'chest_source_height': 8},
            'Common': {
                'head_shot_x': 12, 'head_shot_y': 58,
                'head_shot_x_render_offset': 0, 'head_shot_y_render_offset': 0,
                'mini_map_x_offset': 0, 'mini_map_y_offset': 0
            }
        }
        # JSON输出的键名
        json_key_map = {
            'breath_type': 'BreathType', 'chest_source_x': 'ChestSourceX', 'chest_source_y': 'ChestSourceY',
            'chest_source_width': 'ChestSourceWidth', 'chest_source_height': 'ChestSourceHeight',
            'head_shot_x': 'HeadShotX', 'head_shot_y': 'HeadShotY',
            'head_shot_x_render_offset': 'HeadShotXRenderOffset',
            'head_shot_y_render_offset': 'HeadShotYRenderOffset',
            'mini_map_x_offset': 'MiniMapXOffset', 'mini_map_y_offset': 'MiniMapYOffset'
        }

        output_data = {}
        if sd.breath_type == 1:
            output_data["BreathType"] = "Male"
            breath_defaults = defaults_map['Male']
            for key, default_val in breath_defaults.items():
                current_val = getattr(sd, key)
                if include_defaults or current_val != default_val:
                    output_data[json_key_map[key]] = current_val
        elif sd.breath_type == 2:
            output_data["BreathType"] = "Female"
            breath_defaults = defaults_map['Female']
            for key, default_val in breath_defaults.items():
                current_val = getattr(sd, key)
                if include_defaults or current_val != default_val:
                    output_data[json_key_map[key]] = current_val
        elif include_defaults:
            output_data["BreathType"] = "None"

        for key, default_val in defaults_map['Common'].items():
            current_val = getattr(sd, key)
            if current_val is not None and (include_defaults or current_val != default_val):
                output_data[json_key_map[key]] = current_val

        if not output_data:
            self.root.clipboard_clear()
            self.root.clipboard_append('"Sprite": {}')
            self.show_toast("Copied JSON to clipboard!")
            return

        final_json_obj = {"Sprite": output_data}
        final_string = json.dumps(final_json_obj, indent=4)

        self.root.clipboard_clear()
        self.root.clipboard_append(final_string)
        self.show_toast("Copied JSON to clipboard!")

    def show_toast(self, message: str) -> None:
        """在界面上显示一个短暂的消息提示（Toast）。"""
        toast = tk.Toplevel(self.root)
        toast.overrideredirect(True)
        label = ttk.Label(toast, text=message, style="Toast.TLabel")
        label.pack()
        toast.update_idletasks()
        if self.export_button and self.export_button.winfo_viewable():
            btn_x = self.export_button.winfo_rootx()
            btn_y = self.export_button.winfo_rooty()
            btn_w = self.export_button.winfo_width()
            toast_w = toast.winfo_width()
            toast_h = toast.winfo_height()
            x = btn_x + (btn_w - toast_w) // 2
            y = btn_y - toast_h - 10
            toast.geometry(f"+{x}+{y}")
        toast.lift()
        self.root.after(2000, toast.destroy)


def apply_theme_to_titlebar(root: tk.Tk) -> None:
    """根据操作系统和主题, 美化窗口标题栏。"""
    version = sys.getwindowsversion()

    if version.major == 10 and version.build >= 22000:
        # 在 Windows 11 上设置标题栏颜色以获得更好看的外观
        pywinstyles.change_header_color(root, "#1c1c1c" if sv_ttk.get_theme() == "dark" else "#fafafa")
    elif version.major == 10:
        pywinstyles.apply_style(root, "dark" if sv_ttk.get_theme() == "dark" else "normal")

        # 一种 hacky 的方式来更新 Windows 10 上的标题栏颜色 (它不会像 Win11 那样即时更新)
        root.wm_attributes("-alpha", 0.99)
        root.wm_attributes("-alpha", 1)


def main():
    root = tk.Tk()
    sv_ttk.set_theme("light")
    apply_theme_to_titlebar(root)
    SpriteEditorApp(root)
    root.mainloop()


if __name__ == '__main__':
    main()