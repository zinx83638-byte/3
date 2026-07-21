export type Library = { __current_tab: Tab?, __tabs: { Tab }, __all_elements: { { name: string, frame: Frame } }, __window: { main: Frame, euphoria: ScreenGui }, __resize_start: Vector2?, __size_start: UDim2?, __resizing: boolean, __ui_scale: number, __device: string?, __drag_input: InputObject?, __drag_start: Vector2?, __start_pos: UDim2?, __dragging: boolean?, __minimized: boolean, get_device: (self: Library) -> (), notify: (self: Library, index: { title: string, content: string, duration: number?, notify_type: string }) -> (), get_screen_scale: (self: Library) -> (), mobile_ui_scale: (self: Library) -> (), mobile_controls: (self: Library) -> (), init: (self: Library, title: string?) -> Library, create_tab: (self: Library, name: string, icon: string?) -> Tab }
export type Tab = { __library: Library, button: TextButton, container: ScrollingFrame, label: TextLabel, outline: UIStroke, icon: ImageLabel?, create_button: (self: Tab, index: { title: string, callback: () -> () }) -> (), create_divider: (self: Tab, text: string?) -> (), create_slider: (self: Tab, index: { title: string, minimum: number?, maximum: number?, default: number?, rounding: number?, callback: (value: number) -> () }) -> { Set: (self: any, value: number) -> () }, create_textbox: (self: Tab, index: { title: string, placeholder: string?, callback: (text: string) -> () }) -> { Set: (self: any, text: string) -> (), Get: (self: any) -> string }, create_pastebox: (self: Tab, index: { title: string?, placeholder: string?, height: number?, callback: ((text: string) -> ())? }) -> { Set: (self: any, text: string) -> (), Get: (self: any) -> string, Clear: (self: any) -> () }, create_module: (self: Tab, index: { title: string, default: boolean?, callback: (state: boolean) -> () }) -> Module, create_checkbox: (self: Tab, index: { title: string, default: boolean?, callback: (state: boolean) -> () }) -> (), create_dropdown: (self: Tab, index: { title: string, options: { string }, default: string | { string }?, multi_selection: boolean?, callback: (value: string | { string }) -> () }) -> { Set: (self: any, value: string | { string }) -> () } }
export type Module = { __elements: { Instance }, __library: Library, create_checkbox: (self: Module, index: { title: string, default: boolean?, callback: (state: boolean) -> () }) -> (), create_divider: (self: Module, text: string?) -> (), create_textbox: (self: Module, index: { title: string, placeholder: string?, callback: (text: string) -> () }) -> { Set: (self: any, text: string) -> () }, create_slider: (self: Module, index: { title: string, minimum: number?, maximum: number?, default: number?, rounding: number?, callback: (value: number) -> () }) -> { Set: (self: any, value: number) -> () }, create_button: (self: Module, index: { title: string, callback: () -> () }) -> (), create_dropdown: (self: Module, index: { title: string, options: { string }, default: string | { string }?, multi_selection: boolean?, callback: (value: string | { string }) -> () }) -> { Set: (self: any, value: string | { string }) -> () } }

local Service = setmetatable({} :: any, {
    __index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

        return rawget(self, name)
    end
})

local UserInputService = Service.UserInputService
local CoreGui = Service.CoreGui

local Camera = workspace.CurrentCamera

local Library : Library = {
	__current_tab = nil,
	__tabs = {},

	__all_elements = {},
	__window = {},

	__resize_start = nil,
	__size_start = nil,
	__resizing = false,

	__ui_scale = 1,
	__device = nil,

	__drag_input = nil,
	__drag_start = nil,
	__start_pos = nil,
	__dragging = nil,

	__minimized = false,
	__toggle_key = Enum.KeyCode.RightControl,
	__toggle_window = nil :: any,
	__orb = nil :: any,
}
Library.__index = Library

local function __create_tween(__object : Instance, __properties : { [any]: any }, __duration : number?) : Tween
	local __tween = Service.TweenService:Create(__object, TweenInfo.new(__duration or 0.3, Enum.EasingStyle.Quint), __properties)
	__tween:Play()

	return __tween
end

local function __create_round(__parent : Instance, __radius : number?) : UICorner
	local __corner : UICorner = Instance.new('UICorner')

	__corner.CornerRadius = UDim.new(0, __radius or 8)
	__corner.Parent = __parent

	return __corner
end

local function __create_outline(__parent : Instance) : UIStroke
	local __outline : UIStroke = Instance.new('UIStroke')

	__outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	__outline.Color = Color3.fromRGB(35, 35, 35)
	__outline.Parent = __parent
	__outline.Thickness = 1

	return __outline
end

function Library:get_device() : ()
	local __device : string = 'unknown'

	if not UserInputService.TouchEnabled then
		__device = 'pc'
	else
		__device = 'mobile'
	end

	self.__device = __device
end

local __NotificationQueue : { { title: string, content: string, duration: number?, type: string } } = {}
local __Notifications : { Frame } = {}

local __NotifyIcons : { [string]: string } = {
	normal = 'rbxassetid://10734888000',
	error = 'rbxassetid://10747384394',
	warn = 'rbxassetid://10709753149'
}

local function __update_notification_positions() : ()
	for __i, __notify in ipairs(__Notifications) do
		local __target_y : number = -20

		for __j = #__Notifications, __i + 1, -1 do
			if not __Notifications[__j] or not __Notifications[__j].AbsoluteSize then
				continue
			end

			__target_y = __target_y - __Notifications[__j].AbsoluteSize.Y - 10
		end

		if not __notify or not __notify.Parent then
			continue
		end

		__create_tween(__notify, {Position = UDim2.new(1, -20, 1, __target_y)}, 0.3)
	end
end

local function __notification_init() : ()
	if #__NotificationQueue == 0 then
		return
	end

	local __notification = table.remove(__NotificationQueue, 1)

	local __euphoria_gui = CoreGui:FindFirstChild('Euphoria')

	if not __euphoria_gui then
		return
	end

	local __notify_width : number = 300
	local __notify_height : number = 70

	if Library.__device == 'mobile' or Library.__device == 'unknown' then
		__notify_width = 250
		__notify_height = 60
	end

	local __notify_frame : Frame = Instance.new('Frame')
	__notify_frame.Size = UDim2.new(0, 0, 0, 0)
	__notify_frame.Position = UDim2.new(1, -20, 1, -20)
	__notify_frame.AnchorPoint = Vector2.new(0.5, 0.5)
	__notify_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	__notify_frame.BackgroundTransparency = 0
	__notify_frame.BorderSizePixel = 0
	__notify_frame.ZIndex = 100
	__notify_frame.ClipsDescendants = true
	__notify_frame.Parent = __euphoria_gui

	__create_round(__notify_frame, 4)

	local __icon_container : Frame = Instance.new('Frame')
	__icon_container.Size = UDim2.new(0, 50, 1, 0)
	__icon_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	__icon_container.BackgroundTransparency = 0
	__icon_container.BorderSizePixel = 0
	__icon_container.ZIndex = 101
	__icon_container.Parent = __notify_frame
	__create_round(__icon_container, 8)

	local __icon : ImageLabel = Instance.new('ImageLabel')
	__icon.Size = UDim2.new(0, 24, 0, 24)
	__icon.Position = UDim2.new(0.5, -12, 0.5, -12)
	__icon.BackgroundTransparency = 1
	__icon.Image = __NotifyIcons[__notification.type] or __NotifyIcons['normal']
	__icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	__icon.ZIndex = 102
	__icon.Parent = __icon_container

	local __divider : Frame = Instance.new('Frame')
	__divider.Size = UDim2.new(0, 1, 0.8, 0)
	__divider.Position = UDim2.new(0, 50, 0.1, 0)
	__divider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	__divider.BorderSizePixel = 0
	__divider.ZIndex = 101
	__divider.Parent = __notify_frame

	local __content_container : Frame = Instance.new('Frame')
	__content_container.Size = UDim2.new(1, -60, 1, -8)
	__content_container.Position = UDim2.new(0, 55, 0, 4)
	__content_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	__content_container.BackgroundTransparency = 0
	__content_container.BorderSizePixel = 0
	__content_container.ZIndex = 101
	__content_container.Parent = __notify_frame

	local __title_label : TextLabel = Instance.new('TextLabel')
	__title_label.Size = UDim2.new(1, -10, 0, 18)
	__title_label.Position = UDim2.new(0, 5, 0, 5)
	__title_label.BackgroundTransparency = 1
	__title_label.Text = __notification.title
	__title_label.TextColor3 = Color3.fromRGB(220, 220, 220)
	__title_label.TextSize = 14
	__title_label.Font = Enum.Font.Gotham
	__title_label.TextXAlignment = Enum.TextXAlignment.Left
	__title_label.TextYAlignment = Enum.TextYAlignment.Top
	__title_label.ZIndex = 102
	__title_label.Parent = __content_container

	local __content_label : TextLabel = Instance.new('TextLabel')
	__content_label.Size = UDim2.new(1, -10, 1, -25)
	__content_label.Position = UDim2.new(0, 5, 0, 23)
	__content_label.BackgroundTransparency = 1
	__content_label.Text = __notification.content
	__content_label.TextColor3 = Color3.fromRGB(180, 180, 180)
	__content_label.TextSize = 14
	__content_label.Font = Enum.Font.Gotham
	__content_label.TextXAlignment = Enum.TextXAlignment.Left
	__content_label.TextYAlignment = Enum.TextYAlignment.Top
	__content_label.TextWrapped = true
	__content_label.ZIndex = 102
	__content_label.Parent = __content_container

	local __progress_bar : Frame = Instance.new('Frame')
	__progress_bar.Size = UDim2.new(0, 0, 0, 3)
	__progress_bar.Position = UDim2.new(0, 0, 1, -3)
	__progress_bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	__progress_bar.BorderSizePixel = 0
	__progress_bar.ZIndex = 103
	__progress_bar.Parent = __notify_frame

	table.insert(__Notifications, __notify_frame)

	local __y_position : number = -20

	for __j = #__Notifications - 1, 1, -1 do
		if not __Notifications[__j] or not __Notifications[__j].AbsoluteSize then
			continue
		end

		__y_position = __y_position - __Notifications[__j].AbsoluteSize.Y - 10
	end

	__notify_frame.Position = UDim2.new(1, -20 - (300 / 2), 1, __y_position - (70 / 2))
	__notify_frame.AnchorPoint = Vector2.new(0.5, 0.5)

	__create_tween(__notify_frame, {Size = UDim2.new(0, __notify_width, 0, __notify_height)}, 0.25).Completed:Connect(function()
		__notify_frame.AnchorPoint = Vector2.new(1, 1)
		__notify_frame.Position = UDim2.new(1, -20, 1, __y_position)

		__update_notification_positions()

		__create_tween(__progress_bar, {Size = UDim2.new(1, 0, 0, 3)}, __notification.duration)

		task.wait(__notification.duration)

		__notify_frame.AnchorPoint = Vector2.new(0.5, 0.5)
		__notify_frame.Position = UDim2.new(0, __notify_frame.AbsolutePosition.X + (__notify_frame.AbsoluteSize.X / 2), 0, __notify_frame.AbsolutePosition.Y + (__notify_frame.AbsoluteSize.Y / 2))

		__create_tween(__notify_frame, {BackgroundTransparency = 1}, 0.25)
		__create_tween(__icon_container, {BackgroundTransparency = 1}, 0.25)
		__create_tween(__content_container, {BackgroundTransparency = 1}, 0.25)
		__create_tween(__icon, {ImageTransparency = 1}, 0.25)
		__create_tween(__divider, {BackgroundTransparency = 1}, 0.25)
		__create_tween(__title_label, {TextTransparency = 1}, 0.25)
		__create_tween(__content_label, {TextTransparency = 1}, 0.25)
		__create_tween(__progress_bar, {BackgroundTransparency = 1}, 0.25)

		for _, __child in pairs(__notify_frame:GetChildren()) do
			if not __child:IsA('UIStroke') then
				continue
			end

			__create_tween(__child, {Transparency = 1}, 0.25)
		end

		__create_tween(__notify_frame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3).Completed:Connect(function()
			__notify_frame:Destroy()

			for __i, __notif in ipairs(__Notifications) do
				if __notif ~= __notify_frame then
					continue
				end

				table.remove(__Notifications, __i)

				break
			end

			__update_notification_positions()

			if #__NotificationQueue <= 0 then
				return
			end

			task.spawn(__notification_init)
		end)
	end)
end

function Library:notify(__index : { title: string, content: string, duration: number?, notify_type: string }) : ()
	local __auto_selection : string = __index.notify_type or 'normal'

	if not __NotifyIcons[__auto_selection] then
		__auto_selection = 'normal'
	end

	table.insert(__NotificationQueue, {
		title = __index.title,
		content = __index.content,
		duration = __index.duration or 3,
		notify_type = __auto_selection
	})

	if #__Notifications >= 5 then
		return
	end

	task.spawn(__notification_init)
end

function Library:get_screen_scale() : ()
	local __viewport_size_x : number = Camera.ViewportSize.X

	self.__ui_scale = __viewport_size_x / 1400
end

function Library:mobile_ui_scale() : ()
	if self.__device ~= 'mobile' and self.__device ~= 'unknown' then
		return
	end

	for _, __object in pairs(self.__window.main:GetDescendants()) do
		if __object:IsA('TextLabel') or __object:IsA('TextButton') or __object:IsA('TextBox') then
			if not __object.TextSize then
				continue
			end

			__object.TextSize = math.max(12, math.floor(__object.TextSize * 1.05))
		elseif __object:IsA('ImageLabel') or __object:IsA('ImageButton') then
			if not (__object.Size.X.Offset > 0 and __object.Size.X.Offset < 30) then
				continue
			end

			__object.Size = UDim2.new(0, math.floor(__object.Size.X.Offset * 0.9), 0, math.floor(__object.Size.Y.Offset * 0.9))
		end
	end
end

function Library:mobile_controls() : ()
	if self.__device ~= 'mobile' then
		return
	end

	for _, __obj in pairs(self.__window.main:GetDescendants()) do
		if not ((__obj:IsA('TextButton') or __obj:IsA('ImageButton')) and __obj.Size.Y.Offset < 40) then
			continue
		end

		local __hitbox : Frame = Instance.new('Frame')
		__hitbox.Name = 'TouchHitbox'
		__hitbox.Size = UDim2.new(1, 10, 1, 10)
		__hitbox.Position = UDim2.new(0.5, 0, 0.5, 0)
		__hitbox.AnchorPoint = Vector2.new(0.5, 0.5)
		__hitbox.BackgroundTransparency = 1
		__hitbox.ZIndex = __obj.ZIndex
		__hitbox.Parent = __obj

		if not __obj:IsA('TextButton') then
			continue
		end

		__hitbox.InputBegan:Connect(function(__input)
			if __input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			__obj.MouseButton1Click:Fire()
		end)
	end
end

function Library:init(__title : string?) : Library
	local __euphoria : ScreenGui = Instance.new('ScreenGui')

	__euphoria.Name = 'Euphoria'
	__euphoria.ResetOnSpawn = false
	__euphoria.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	__euphoria.Parent = CoreGui

	self:get_device()
	self.__window = {}

	local __main : Frame = Instance.new('Frame')
	__main.Name = 'Main'
	__main.Size = UDim2.new(0, 0, 0, 0)
	__main.Position = UDim2.new(0.5, 0, 0.5, 0)
	__main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	__main.BackgroundTransparency = 0.1
	__main.BorderSizePixel = 0
	__main.ClipsDescendants = true
	__main.Parent = __euphoria
	__create_round(__main, 50)

	self.__window.main = __main
	self.__window.euphoria = __euphoria

	local __UIScale : UIScale = Instance.new('UIScale')
	__UIScale.Parent = __main

	if self.__device == 'mobile' or self.__device == 'unknown' then
		self:get_screen_scale()

		__UIScale.Scale = math.min(self.__ui_scale * 1.2, 1)

		Camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
			self:get_screen_scale()

			__UIScale.Scale = math.min(self.__ui_scale * 1.2, 1)
		end)
	end

	local __blur_frame : Frame = Instance.new('Frame')
	__blur_frame.Size = UDim2.new(1, 0, 1, 0)
	__blur_frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	__blur_frame.BackgroundTransparency = 0
	__blur_frame.BorderSizePixel = 0
	__blur_frame.ZIndex = 0
	__blur_frame.Parent = __main
	__create_round(__blur_frame, 12)
	__create_outline(__blur_frame)

	local __header : Frame = Instance.new('Frame')
	__header.Name = 'Header'
	__header.Size = UDim2.new(1, 0, 0, 50)
	__header.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	__header.BackgroundTransparency = 1
	__header.BorderSizePixel = 0
	__header.ZIndex = 2
	__header.Parent = __main
	__create_round(__header, 6)

	local __header_outline_bottom : Frame = Instance.new('Frame')
	__header_outline_bottom.Size = UDim2.new(1, 0, 0, 1)
	__header_outline_bottom.Position = UDim2.new(0, 0, 1, -1)
	__header_outline_bottom.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	__header_outline_bottom.BorderSizePixel = 0
	__header_outline_bottom.ZIndex = 3
	__header_outline_bottom.Parent = __header

	local __title_label : TextLabel = Instance.new('TextLabel')
	__title_label.Size = UDim2.new(0, 150, 1, 0)
	__title_label.Position = UDim2.new(0, 20, 0, 0)
	__title_label.BackgroundTransparency = 1
	__title_label.Text = 'laced.max'
	__title_label.TextColor3 = Color3.fromRGB(255, 255, 255)
	__title_label.TextSize = 16
	__title_label.Font = Enum.Font.Gotham
	__title_label.TextXAlignment = Enum.TextXAlignment.Left
	__title_label.ZIndex = 3
	__title_label.Parent = __header

	local __search_container : Frame = Instance.new('Frame')
	__search_container.Size = UDim2.new(0, 180, 0, 32)
	__search_container.Position = UDim2.new(1, -190, 0.5, -16)
	__search_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	__search_container.BackgroundTransparency = 0.4
	__search_container.BorderSizePixel = 0
	__search_container.ZIndex = 3
	__search_container.Parent = __header
	__create_round(__search_container, 6)
	__create_outline(__search_container)

	local __search_icon_container : Frame = Instance.new('Frame')
	__search_icon_container.Size = UDim2.new(0, 30, 1, 0)
	__search_icon_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	__search_icon_container.BackgroundTransparency = 0.6
	__search_icon_container.BorderSizePixel = 0
	__search_icon_container.ZIndex = 3
	__search_icon_container.Parent = __search_container
	__create_round(__search_icon_container, 6)

	local __search_divider : Frame = Instance.new('Frame')
	__search_divider.Size = UDim2.new(0, 1, 0.6, 0)
	__search_divider.Position = UDim2.new(0, 30, 0.2, 0)
	__search_divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	__search_divider.BorderSizePixel = 0
	__search_divider.ZIndex = 4
	__search_divider.Parent = __search_container

	local __search_icon : ImageLabel = Instance.new('ImageLabel')
	__search_icon.Size = UDim2.new(0, 16, 0, 16)
	__search_icon.Position = UDim2.new(0.5, -8, 0.5, -8)
	__search_icon.BackgroundTransparency = 1
	__search_icon.Image = 'rbxassetid://10734943674'
	__search_icon.ImageColor3 = Color3.fromRGB(120, 120, 120)
	__search_icon.ZIndex = 4
	__search_icon.Parent = __search_icon_container

	local __search_box : TextBox = Instance.new('TextBox')
	__search_box.Size = UDim2.new(1, -40, 1, 0)
	__search_box.Position = UDim2.new(0, 35, 0, 0)
	__search_box.BackgroundTransparency = 1
	__search_box.Text = ''
	__search_box.PlaceholderText = 'Search'
	__search_box.TextColor3 = Color3.fromRGB(255, 255, 255)
	__search_box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	__search_box.TextSize = 13
	__search_box.Font = Enum.Font.Gotham
	__search_box.TextXAlignment = Enum.TextXAlignment.Left
	__search_box.ClearTextOnFocus = false
	__search_box.ZIndex = 4
	__search_box.Parent = __search_container

	__search_box:GetPropertyChangedSignal('Text'):Connect(function()
		local __search_text : string = __search_box.Text:lower()

		for _, __element in pairs(self.__all_elements) do
			local __is_divider : boolean = __element.frame.Name == 'Divider' or __element.frame.Name == 'DividerItem'

			if __search_text == '' then
				__element.frame.Visible = true

				if not __is_divider then
					__element.frame.BackgroundTransparency = 0.3

					__create_tween(__element.frame, {BackgroundTransparency = 0.3}, 0.2)
				end
			else
				if __is_divider then
					__element.frame.Visible = false
				else
					local __element_text : string = __element.name:lower()

					if __element_text:find(__search_text) == nil then
						__create_tween(__element.frame, {BackgroundTransparency = 1}, 0.2)

						task.delay(0.2, function()
							if __search_box.Text:lower():find(__element_text) == nil then
								__element.frame.Visible = false
							end
						end)
					else
						__element.frame.Visible = true

						__create_tween(__element.frame, {BackgroundTransparency = 0.3}, 0.2)
					end
				end
			end
		end
	end)

	local __resize_button : ImageButton = Instance.new('ImageButton')
	__resize_button.Size = UDim2.new(0, 20, 0, 20)
	__resize_button.Position = UDim2.new(1, -25, 1, -25)
	__resize_button.BackgroundTransparency = 1
	__resize_button.Image = 'rbxassetid://10734961133'
	__resize_button.ImageColor3 = Color3.fromRGB(120, 120, 120)
	__resize_button.ZIndex = 10
	__resize_button.Parent = __main

	self.__resizing = false

	if self.__device == 'mobile' or self.__device == 'unknown' then
		local __resize_hitbox : Frame = Instance.new('Frame')

		__resize_hitbox.Size = UDim2.new(0, 50, 0, 50)
		__resize_hitbox.Position = UDim2.new(1, -50, 1, -50)
		__resize_hitbox.BackgroundTransparency = 1
		__resize_hitbox.ZIndex = 9
		__resize_hitbox.Parent = __main

		__resize_hitbox.InputBegan:Connect(function(__input)
			if __input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			self.__resizing = true

			self.__resize_start = Vector2.new(__input.Position.X, __input.Position.Y)
			self.__size_start = __main.Size
		end)

		__resize_hitbox.InputChanged:Connect(function(__input)
			if not self.__resizing or __input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			local __current_pos : Vector2 = Vector2.new(__input.Position.X, __input.Position.Y)
			local __delta : Vector2 = __current_pos - self.__resize_start

			local __new_width : number = math.max(300, self.__size_start.X.Offset + __delta.X)
			local __new_height : number = math.max(250, self.__size_start.Y.Offset + __delta.Y)

			__main.Size = UDim2.new(0, __new_width, 0, __new_height)
		end)

		__resize_hitbox.InputEnded:Connect(function(__input)
			if __input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			self.__resizing = false
		end)
	end

	__resize_button.MouseButton1Down:Connect(function()
		if self.__device ~= 'pc' then
			return
		end

		self.__resizing = true

		self.__resize_start = UserInputService:GetMouseLocation()
		self.__size_start = __main.Size
	end)

	__resize_button.InputBegan:Connect(function(__input)
		if __input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		self.__resizing = true

		self.__resize_start = Vector2.new(__input.Position.X, __input.Position.Y)
		self.__size_start = __main.Size
	end)

	__resize_button.InputChanged:Connect(function(__input)
		if not self.__resizing or __input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local __current_pos : Vector2 = Vector2.new(__input.Position.X, __input.Position.Y)
		local __delta : Vector2 = __current_pos - self.__resize_start

		local __new_width : number = math.max(300, self.__size_start.X.Offset + __delta.X)
		local __new_height : number = math.max(250, self.__size_start.Y.Offset + __delta.Y)

		__main.Size = UDim2.new(0, __new_width, 0, __new_height)
	end)

	__resize_button.InputEnded:Connect(function(__input)
		if __input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		self.__resizing = false
	end)

	UserInputService.InputEnded:Connect(function(__input)
		if __input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		self.__resizing = false
	end)

	UserInputService.InputChanged:Connect(function(__input)
		if not self.__resizing or __input.UserInputType ~= Enum.UserInputType.MouseMovement or self.__device ~= 'pc' then
			return
		end

		local __delta : Vector2 = UserInputService:GetMouseLocation() - self.__resize_start

		__create_tween(__main, {Size = UDim2.new(0, math.max(400, self.__size_start.X.Offset + __delta.X), 0, math.max(300, self.__size_start.Y.Offset + __delta.Y))}, 0.5)
	end)

	task.spawn(function()
		task.wait(0.05)

		local __target_width : number = 700
		local __target_height : number = 450

		if self.__device == 'mobile' or self.__device == 'unknown' then
			self:get_screen_scale()

			__target_width = math.floor(Camera.ViewportSize.X * 0.85)
			__target_height = math.floor(Camera.ViewportSize.Y * 0.75)
		end

		local __grow_tween = __create_tween(__main, {
			Size = UDim2.new(0, __target_width, 0, __target_height),
			Position = UDim2.new(0.5, -__target_width/2, 0.5, -__target_height/2)
		}, 0.25)

		__grow_tween.Completed:Connect(function()
			__main.ClipsDescendants = false

			if self.__device == 'mobile' or self.__device == 'unknown' then
				self:mobile_ui_scale()
				self:mobile_controls()
			end
		end)
	end)

	local __original_size : UDim2 = __main.Size
	local __original_position : UDim2 = __main.Position

	local __is_animating : boolean = false
	local __current_tweens : { Tween } = {}

	local __saved_scroll_positions : { [ScrollingFrame]: Vector2 } = {}

	self.__toggle_key = Enum.KeyCode.RightControl

	self.__toggle_window = function()
		if __is_animating then
			return
		end

		if not self.__minimized then
			if self.__current_tab and self.__current_tab.container then
				__saved_scroll_positions[self.__current_tab.container] = self.__current_tab.container.CanvasPosition
			end

			if __main.Visible and __main.Size.X.Offset > 0 then
				__original_size = __main.Size
				__original_position = __main.Position
			end

			self.__minimized = true
			__main.Visible = false
			__main.ClipsDescendants = false
		else
			self.__minimized = false
			__main.Visible = true
			__main.Size = __original_size
			__main.Position = __original_position
			__main.BackgroundTransparency = 0.1
			__main.ClipsDescendants = false

			if self.__current_tab and self.__current_tab.container then
				local __container = self.__current_tab.container

				__container.ScrollBarImageTransparency = 0
				__container.Active = true
				__container.ScrollingEnabled = true

				if __saved_scroll_positions[__container] then
					__container.CanvasPosition = __saved_scroll_positions[__container]
				end
			end
		end
	end

	UserInputService.InputBegan:Connect(function(__input, __process)
		if __process then
			return
		end

		if __input.KeyCode ~= self.__toggle_key then
			return
		end

		self.__toggle_window()
	end)

	local __is_mobile = self.__device == 'mobile' or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)

	if __is_mobile then
		local __orb_sz = 56
		local __orb : TextButton = Instance.new('TextButton')
		__orb.Name = 'ToggleOrb'
		__orb.Size = UDim2.new(0, __orb_sz, 0, __orb_sz)
		__orb.Position = UDim2.new(1, -(__orb_sz + 16), 0.6, -(__orb_sz / 2))
		__orb.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		__orb.BackgroundTransparency = 0.2
		__orb.BorderSizePixel = 0
		__orb.AutoButtonColor = false
		__orb.Text = 'E'
		__orb.TextColor3 = Color3.fromRGB(255, 255, 255)
		__orb.TextSize = 22
		__orb.Font = Enum.Font.GothamBold
		__orb.ZIndex = 200
		__orb.Parent = __euphoria
		__create_round(__orb, math.floor(__orb_sz / 2))

		local __orb_stroke : UIStroke = Instance.new('UIStroke')
		__orb_stroke.Color = Color3.fromRGB(40, 40, 40)
		__orb_stroke.Thickness = 1
		__orb_stroke.Parent = __orb

		self.__orb = __orb
		self.__window.orb = __orb

		local __orb_dragging = false
		local __orb_drag_start : Vector2? = nil
		local __orb_start_pos : UDim2? = nil
		local __orb_moved = false

		local __orb_base = Vector2.zero

		__orb.InputBegan:Connect(function(__input)
			if __input.UserInputType ~= Enum.UserInputType.MouseButton1 and __input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			__orb_dragging = true
			__orb_moved = false
			__orb_drag_start = __input.Position
			__orb_base = Vector2.new(__orb.AbsolutePosition.X, __orb.AbsolutePosition.Y)
		end)

		__orb.InputEnded:Connect(function(__input)
			if __input.UserInputType ~= Enum.UserInputType.MouseButton1 and __input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if __orb_dragging and not __orb_moved then
				self.__toggle_window()
			end

			__orb_dragging = false
		end)

		UserInputService.InputChanged:Connect(function(__input)
			if not __orb_dragging or not __orb_drag_start then
				return
			end

			if __input.UserInputType ~= Enum.UserInputType.MouseMovement and __input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			local __delta = __input.Position - __orb_drag_start

			if math.abs(__delta.X) > 6 or math.abs(__delta.Y) > 6 then
				__orb_moved = true
			end

			if not __orb_moved then
				return
			end

			local __cam = workspace.CurrentCamera
			local __vx = __cam and __cam.ViewportSize.X or 1920
			local __vy = __cam and __cam.ViewportSize.Y or 1080
			local __nx = math.clamp(__orb_base.X + __delta.X, 8, math.max(8, __vx - __orb_sz - 8))
			local __ny = math.clamp(__orb_base.Y + __delta.Y, 8, math.max(8, __vy - __orb_sz - 8))

			__orb.Position = UDim2.fromOffset(__nx, __ny)
		end)
	else
		self.__orb = nil
	end

	local __tab_container : Frame = Instance.new('Frame')
	__tab_container.Name = 'TabContainer'
	__tab_container.Size = UDim2.new(0, 140, 1, -51)
	__tab_container.Position = UDim2.new(0, 6.7, 0, 51)
	__tab_container.BackgroundTransparency = 1
	__tab_container.BorderSizePixel = 0
	__tab_container.ZIndex = 2
	__tab_container.Parent = __main

	local __tab_separator : Frame = Instance.new('Frame')
	__tab_separator.Size = UDim2.new(0, 1, 1, -49)
	__tab_separator.Position = UDim2.new(0, 150, 0, 49)
	__tab_separator.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	__tab_separator.BorderSizePixel = 0
	__tab_separator.ZIndex = 2
	__tab_separator.Parent = __main

	local __tab_layout : UIListLayout = Instance.new('UIListLayout')
	__tab_layout.Padding = UDim.new(0, 5)
	__tab_layout.SortOrder = Enum.SortOrder.LayoutOrder
	__tab_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	__tab_layout.Parent = __tab_container

	local __tab_padding : UIPadding = Instance.new('UIPadding')
	__tab_padding.PaddingTop = UDim.new(0, 8)
	__tab_padding.Parent = __tab_container

	__header.InputBegan:Connect(function(__input)
		if __input.UserInputType ~= Enum.UserInputType.MouseButton1 and __input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		self.__dragging = true

		self.__drag_start = __input.Position
		self.__start_pos = __main.Position

		__input.Changed:Connect(function()
			if __input.UserInputState ~= Enum.UserInputState.End then
				return
			end

			self.__dragging = false
		end)
	end)

	__header.InputChanged:Connect(function(__input)
		if __input.UserInputType ~= Enum.UserInputType.MouseMovement and __input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		self.__drag_input = __input
	end)

	UserInputService.InputChanged:Connect(function(__input)
		if __input ~= self.__drag_input or not self.__dragging then
			return
		end

		local __delta : Vector2 = __input.Position - self.__drag_start

		__create_tween(__main, {
			Position = UDim2.new(self.__start_pos.X.Scale, self.__start_pos.X.Offset + __delta.X, self.__start_pos.Y.Scale, self.__start_pos.Y.Offset + __delta.Y)
		}, 0.5)
	end)

	function Library:create_tab(__name : string, __icon : string?) : Tab
		local __tab : Tab = {}
		__tab.__library = self

		local __tab_button : TextButton = Instance.new('TextButton')
		__tab_button.Size = UDim2.new(1, -10, 0, 35)
		__tab_button.Position = UDim2.new(0, 5, 0, 0)
		__tab_button.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		__tab_button.BackgroundTransparency = 1
		__tab_button.BorderSizePixel = 0
		__tab_button.Text = ''
		__tab_button.AutoButtonColor = false
		__tab_button.ClipsDescendants = true
		__tab_button.ZIndex = 3
		__tab_button.Parent = __tab_container
		__create_round(__tab_button, 6)

		local __tab_outline : UIStroke = __create_outline(__tab_button)
		__tab_outline.Transparency = 1

		local __tab_icon : ImageLabel?
		local __label_x_offset : number = 10

		if __icon then
			__tab_icon = Instance.new('ImageLabel')
			__tab_icon.Size = UDim2.new(0, 16, 0, 16)
			__tab_icon.Position = UDim2.new(0, 10, 0.5, -8)
			__tab_icon.BackgroundTransparency = 1
			__tab_icon.Image = __icon
			__tab_icon.ImageColor3 = Color3.fromRGB(120, 120, 120)
			__tab_icon.ZIndex = 4
			__tab_icon.Parent = __tab_button
			__label_x_offset = 32
		end

		local __tab_label : TextLabel = Instance.new('TextLabel')
		__tab_label.Size = UDim2.new(1, -__label_x_offset - 10, 1, 0)
		__tab_label.Position = UDim2.new(0, __label_x_offset, 0, 0)
		__tab_label.BackgroundTransparency = 1
		__tab_label.Text = __name
		__tab_label.TextColor3 = Color3.fromRGB(120, 120, 120)
		__tab_label.TextSize = 14
		__tab_label.Font = Enum.Font.GothamMedium
		__tab_label.TextXAlignment = Enum.TextXAlignment.Left
		__tab_label.ZIndex = 4
		__tab_label.Parent = __tab_button

		local __container : ScrollingFrame = Instance.new('ScrollingFrame')
		__container.Name = __name .. 'Container'
		__container.Size = UDim2.new(1, -170, 1, -61)
		__container.Position = UDim2.new(0, 160, 0, 51)
		__container.BackgroundTransparency = 1
		__container.BorderSizePixel = 0
		__container.ScrollBarThickness = 4
		__container.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
		__container.CanvasSize = UDim2.new(0, 0, 0, 0)
		__container.Visible = false
		__container.ZIndex = 2
		__container.Parent = __main

		local __layout : UIListLayout = Instance.new('UIListLayout')
		__layout.Padding = UDim.new(0, 6)
		__layout.SortOrder = Enum.SortOrder.LayoutOrder
		__layout.Parent = __container

		local __container_padding : UIPadding = Instance.new('UIPadding')
		__container_padding.PaddingTop = UDim.new(0, 10)
		__container_padding.PaddingLeft = UDim.new(0, 1)
		__container_padding.PaddingRight = UDim.new(0, 15)
		__container_padding.PaddingBottom = UDim.new(0, 20)
		__container_padding.Parent = __container

		__layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			local __padding_bottom : number = __container_padding.PaddingBottom.Offset or 0

			__container.CanvasSize = UDim2.new(0, 0, 0, __layout.AbsoluteContentSize.Y + __container_padding.PaddingTop.Offset + __padding_bottom + 10)
		end)

		local function __activate_tab()
			for _, __t in pairs(self.__tabs) do
				__t.container.Visible = false

				__t.button.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__t.label.TextColor3 = Color3.fromRGB(120, 120, 120)
				__t.outline.Transparency = 1

				if __t.icon then
					__t.icon.ImageColor3 = Color3.fromRGB(120, 120, 120)
				end
			end

			__container.Visible = true

			local __layout_order : number = 0

			for _, __child in ipairs(__container:GetChildren()) do
				if not __child:IsA('Frame') then
					continue
				end

				__child.LayoutOrder = __layout_order
				__layout_order += 1

				local __original_pos : UDim2 = __child.Position
				__child.Position = UDim2.new(0, 0, 0, -20)

				local __target_transparency : number = 1

				if __child.Name == 'Divider' then
					__target_transparency = 1
				elseif __child.Name:find('Module') then
					__target_transparency = 0.3
					__child.BackgroundTransparency = 1
				elseif __child.Name:find('Button') or __child.Name:find('Checkbox') or __child.Name:find('Dropdown') then
					__target_transparency = 0.3
					__child.BackgroundTransparency = 1
				else
					__child.BackgroundTransparency = 1
				end

				local __outline_child = __child:FindFirstChild('UIStroke')

				if __outline_child then
					__outline_child.Transparency = 1
				end

				task.delay(__child.LayoutOrder * 0.03, function()
					__create_tween(__child, {
						Position = __original_pos,
						BackgroundTransparency = __target_transparency
					}, 0.25)

					if __outline_child then
						__create_tween(__outline_child, {Transparency = 0}, 0.25)
					end
				end)
			end

			__tab_button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			__tab_label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__tab_outline.Transparency = 0

			if __tab_icon then
				__tab_icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			end

			self.__current_tab = __tab
		end

		__tab_button.MouseButton1Click:Connect(__activate_tab)

		__tab.button = __tab_button
		__tab.container = __container
		__tab.label = __tab_label
		__tab.outline = __tab_outline
		__tab.icon = __tab_icon

		table.insert(self.__tabs, __tab)

		if #self.__tabs == 1 then
			__activate_tab()
		end

		function __tab:create_button(__index : { title: string, callback: () -> () })
			local __button_frame : Frame = Instance.new('Frame')
			__button_frame.Name = 'Button'
			__button_frame.Size = UDim2.new(1, 2, 0, 40)
			__button_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__button_frame.BackgroundTransparency = 0.3
			__button_frame.BorderSizePixel = 0
			__button_frame.ZIndex = 3
			__button_frame.Parent = __container
			__create_round(__button_frame, 8)
			__create_outline(__button_frame)

			local __icon : ImageLabel = Instance.new('ImageLabel')
			__icon.Size = UDim2.new(0, 18, 0, 18)
			__icon.Position = UDim2.new(1, -35, 0.5, -9)
			__icon.BackgroundTransparency = 1
			__icon.Image = 'rbxassetid://10709791437'
			__icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			__icon.ZIndex = 4
			__icon.Parent = __button_frame

			local __label : TextLabel = Instance.new('TextLabel')
			__label.Size = UDim2.new(1, -60, 1, 0)
			__label.Position = UDim2.new(0, 15, 0, 0)
			__label.BackgroundTransparency = 1
			__label.Text = __index.title
			__label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__label.TextSize = 15
			__label.Font = Enum.Font.Gotham
			__label.TextXAlignment = Enum.TextXAlignment.Left
			__label.ZIndex = 4
			__label.Parent = __button_frame

			local __button : TextButton = Instance.new('TextButton')
			__button.Size = UDim2.new(1, 0, 1, 0)
			__button.BackgroundTransparency = 1
			__button.Text = ''
			__button.ZIndex = 5
			__button.Parent = __button_frame

			__button.MouseButton1Click:Connect(function()
				__create_tween(__button_frame, {BackgroundColor3 = Color3.fromRGB(15, 15, 15)}, 0.1)

				task.delay(0.12, function()
					__create_tween(__button_frame, {BackgroundColor3 = Color3.fromRGB(8, 8, 8)}, 0.2)
				end)

				if __index.callback then
					__index.callback()
				end
			end)

			table.insert(self.__library.__all_elements, {name = __index.title, frame = __button_frame})
		end

		function __tab:create_divider(__text : string?)
			local __divider_frame : Frame = Instance.new('Frame')
			__divider_frame.Name = 'Divider'
			__divider_frame.Size = UDim2.new(1, 9, 0, 23)
			__divider_frame.BackgroundTransparency = 1
			__divider_frame.BorderSizePixel = 0
			__divider_frame.ZIndex = 3
			__divider_frame.Parent = __container
			__divider_frame.LayoutOrder = 0

			local __divider_label : TextLabel = Instance.new('TextLabel')
			__divider_label.Size = UDim2.new(1, -20, 1, 0)
			__divider_label.Position = UDim2.new(0, 5, 0, 0)
			__divider_label.BackgroundTransparency = 1
			__divider_label.Text = __text or ''
			__divider_label.TextColor3 = Color3.fromRGB(60, 60, 60)
			__divider_label.TextSize = 14
			__divider_label.Font = Enum.Font.GothamBold
			__divider_label.TextXAlignment = Enum.TextXAlignment.Left
			__divider_label.ZIndex = 4
			__divider_label.Parent = __divider_frame

			table.insert(self.__library.__all_elements, {name = __text or '', frame = __divider_frame})
		end

		function __tab:create_slider(__index : { title: string, minimum: number?, maximum: number?, default: number?, rounding: number?, callback: (value: number) -> () }) : { Set: (self: any, value: number) -> () }
			local __min : number = __index.minimum or 0
			local __max : number = __index.maximum or 100

			local __default : number = __index.default or __min
			local __rounding : number = __index.rounding or 0

			local __callback : (value: number) -> () = __index.callback or (function() end)

			local __value : number = __default
			local __dragging : boolean = false

			local __slider_frame : Frame = Instance.new('Frame')
			__slider_frame.Name = 'Slider'
			__slider_frame.Size = UDim2.new(1, 3, 0, 50)
			__slider_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__slider_frame.BackgroundTransparency = 0.3
			__slider_frame.BorderSizePixel = 0
			__slider_frame.ZIndex = 3
			__slider_frame.Parent = __container
			__create_round(__slider_frame, 8)
			__create_outline(__slider_frame)

			local __label : TextLabel = Instance.new('TextLabel')
			__label.Size = UDim2.new(0.6, 0, 0, 20)
			__label.Position = UDim2.new(0, 15, 0, 8)
			__label.BackgroundTransparency = 1
			__label.Text = __index.title
			__label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__label.TextSize = 16
			__label.Font = Enum.Font.Gotham
			__label.TextXAlignment = Enum.TextXAlignment.Left
			__label.ZIndex = 4
			__label.Parent = __slider_frame

			local __value_label : TextLabel = Instance.new('TextLabel')
			__value_label.Size = UDim2.new(0.3, 0, 0, 20)
			__value_label.Position = UDim2.new(0.7, -15, 0, 8)
			__value_label.BackgroundTransparency = 1
			__value_label.Text = tostring(__value)
			__value_label.TextColor3 = Color3.fromRGB(120, 120, 120)
			__value_label.TextSize = 13
			__value_label.Font = Enum.Font.GothamMedium
			__value_label.TextXAlignment = Enum.TextXAlignment.Right
			__value_label.ZIndex = 4
			__value_label.Parent = __slider_frame

			local __slider_track_bg : Frame = Instance.new('Frame')
			__slider_track_bg.Size = UDim2.new(1, -30, 0, 4)
			__slider_track_bg.Position = UDim2.new(0, 15, 1, -18)
			__slider_track_bg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			__slider_track_bg.BorderSizePixel = 0
			__slider_track_bg.ZIndex = 4
			__slider_track_bg.Parent = __slider_frame
			__create_round(__slider_track_bg, 2)

			local __slider_hitbox : Frame = Instance.new('Frame')
			__slider_hitbox.Size = UDim2.new(1, 0, 0, 20)
			__slider_hitbox.Position = UDim2.new(0, 0, 0.5, -10)
			__slider_hitbox.BackgroundTransparency = 1
			__slider_hitbox.ZIndex = 7
			__slider_hitbox.Parent = __slider_track_bg

			local __slider_track : Frame = Instance.new('Frame')
			__slider_track.Size = UDim2.new(0, 0, 1, 0)
			__slider_track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			__slider_track.BorderSizePixel = 0
			__slider_track.ZIndex = 5
			__slider_track.Parent = __slider_track_bg
			__create_round(__slider_track, 2)

			local __slider_ball : Frame = Instance.new('Frame')
			__slider_ball.Size = UDim2.new(0, 10, 0, 10)
			__slider_ball.Position = UDim2.new(1, -5, 0.5, -5)
			__slider_ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			__slider_ball.BorderSizePixel = 0
			__slider_ball.ZIndex = 6
			__slider_ball.Parent = __slider_track
			__create_round(__slider_ball, 5)
			__create_outline(__slider_ball)

			local function __update_slider(__input : InputObject)
				local __position : number = math.clamp((__input.Position.X - __slider_track_bg.AbsolutePosition.X) / __slider_track_bg.AbsoluteSize.X, 0, 1)

				__value = math.floor(__min + (__max - __min) * __position)

				if __rounding > 0 then
					__value = math.floor(__value / __rounding) * __rounding
				end

				__value = math.clamp(__value, __min, __max)
				__value_label.Text = tostring(__value)

				__create_tween(__slider_track, {Size = UDim2.new(__position, 0, 1, 0)}, 0.1)

				__callback(__value)
			end

			local function __set_value(__new_value : number)
				__value = math.clamp(__new_value, __min, __max)

				if __rounding > 0 then
					__value = math.floor(__value / __rounding) * __rounding
				end

				__value_label.Text = tostring(__value)
				__slider_track.Size = UDim2.new((__value - __min) / (__max - __min), 0, 1, 0)

				__callback(__value)
			end

			__set_value(__default)

			__slider_hitbox.InputBegan:Connect(function(__input)
				if __input.UserInputType ~= Enum.UserInputType.MouseButton1 and __input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				__dragging = true

				__create_tween(__slider_ball, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6)}, 0.2)
				__update_slider(__input)
			end)

			__slider_hitbox.InputEnded:Connect(function(__input)
				if __input.UserInputType ~= Enum.UserInputType.MouseButton1 and __input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				__dragging = false

				__create_tween(__slider_ball, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -5, 0.5, -5)}, 0.2)
			end)

			UserInputService.InputChanged:Connect(function(__input)
				if not __dragging or (__input.UserInputType ~= Enum.UserInputType.MouseMovement and __input.UserInputType ~= Enum.UserInputType.Touch) then
					return
				end

				__update_slider(__input)
			end)

			table.insert(self.__library.__all_elements, {name = __index.title, frame = __slider_frame})

			return {
				Set = function(__self, __new_value : number)
					__set_value(__new_value)
				end
			}
		end

		function __tab:create_textbox(__index : { title: string, placeholder: string?, callback: (text: string) -> () }) : { Set: (self: any, text: string) -> (), Get: (self: any) -> string }
			local __callback : (text: string) -> () = __index.callback or (function() end)

			local __textbox_frame : Frame = Instance.new('Frame')
			__textbox_frame.Name = 'Textbox'
			__textbox_frame.Size = UDim2.new(1, 2, 0, 40)
			__textbox_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__textbox_frame.BackgroundTransparency = 0.3
			__textbox_frame.BorderSizePixel = 0
			__textbox_frame.ClipsDescendants = true
			__textbox_frame.ZIndex = 3
			__textbox_frame.Parent = __container
			__create_round(__textbox_frame, 8)
			__create_outline(__textbox_frame)

			local __label : TextLabel = Instance.new('TextLabel')
			__label.Size = UDim2.new(0, 100, 1, 0)
			__label.Position = UDim2.new(0, 15, 0, 0)
			__label.BackgroundTransparency = 1
			__label.Text = __index.title
			__label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__label.TextSize = 16
			__label.Font = Enum.Font.Gotham
			__label.TextXAlignment = Enum.TextXAlignment.Left
			__label.TextTruncate = Enum.TextTruncate.AtEnd
			__label.ZIndex = 4
			__label.Parent = __textbox_frame

			local __input_container : Frame = Instance.new('Frame')
			__input_container.Size = UDim2.new(0, 200, 0, 28)
			__input_container.Position = UDim2.new(1, -210, 0.5, -14)
			__input_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__input_container.BackgroundTransparency = 0.4
			__input_container.BorderSizePixel = 0
			__input_container.ClipsDescendants = true
			__input_container.ZIndex = 4
			__input_container.Parent = __textbox_frame
			__create_round(__input_container, 6)
			__create_outline(__input_container)

			local __icon_container : Frame = Instance.new('Frame')
			__icon_container.Size = UDim2.new(0, 28, 1, 0)
			__icon_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__icon_container.BackgroundTransparency = 0.6
			__icon_container.BorderSizePixel = 0
			__icon_container.ZIndex = 4
			__icon_container.Parent = __input_container
			__create_round(__icon_container, 6)

			local __input_divider : Frame = Instance.new('Frame')
			__input_divider.Size = UDim2.new(0, 1, 0.6, 0)
			__input_divider.Position = UDim2.new(0, 28, 0.2, 0)
			__input_divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			__input_divider.BorderSizePixel = 0
			__input_divider.ZIndex = 5
			__input_divider.Parent = __input_container

			local __textbox_icon : ImageLabel = Instance.new('ImageLabel')
			__textbox_icon.Size = UDim2.new(0, 16, 0, 16)
			__textbox_icon.Position = UDim2.new(0.5, -8, 0.5, -8)
			__textbox_icon.BackgroundTransparency = 1
			__textbox_icon.Image = 'rbxassetid://10723433811'
			__textbox_icon.ImageColor3 = Color3.fromRGB(120, 120, 120)
			__textbox_icon.ZIndex = 5
			__textbox_icon.Parent = __icon_container

			local __textbox : TextBox = Instance.new('TextBox')
			__textbox.Size = UDim2.new(1, -35, 1, 0)
			__textbox.Position = UDim2.new(0, 32, 0, 0)
			__textbox.BackgroundTransparency = 1
			__textbox.Text = ''
			__textbox.PlaceholderText = __index.placeholder or ''
			__textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
			__textbox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
			__textbox.TextSize = 13
			__textbox.Font = Enum.Font.Gotham
			__textbox.TextXAlignment = Enum.TextXAlignment.Left
			__textbox.TextTruncate = Enum.TextTruncate.AtEnd
			__textbox.ClearTextOnFocus = false
			__textbox.ClipsDescendants = true
			__textbox.ZIndex = 5
			__textbox.Parent = __input_container

			__textbox.FocusLost:Connect(function(__enter_pressed)
				if not __enter_pressed then
					return
				end

				__callback(__textbox.Text)
			end)

			table.insert(self.__library.__all_elements, {name = __index.title, frame = __textbox_frame})

			return {
				Set = function(__self, __new_text : string)
					__textbox.Text = __new_text
				end,
				Get = function()
					return __textbox.Text
				end,
			}
		end

		function __tab:create_pastebox(__index : { title: string?, placeholder: string?, height: number?, callback: ((text: string) -> ())? }) : { Set: (self: any, text: string) -> (), Get: (self: any) -> string, Clear: (self: any) -> () }
			local __height : number = math.clamp(__index.height or 140, 80, 320)
			local __on_change = __index.callback

			local __frame : Frame = Instance.new('Frame')
			__frame.Name = 'Pastebox'
			__frame.Size = UDim2.new(1, 2, 0, __height)
			__frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__frame.BackgroundTransparency = 0.3
			__frame.BorderSizePixel = 0
			__frame.ClipsDescendants = true
			__frame.ZIndex = 3
			__frame.Parent = __container
			__create_round(__frame, 8)
			__create_outline(__frame)

			local __title = __index.title or 'Paste'

			local __label : TextLabel = Instance.new('TextLabel')
			__label.Size = UDim2.new(1, -24, 0, 22)
			__label.Position = UDim2.new(0, 12, 0, 6)
			__label.BackgroundTransparency = 1
			__label.Text = __title
			__label.TextColor3 = Color3.fromRGB(200, 200, 200)
			__label.TextSize = 13
			__label.Font = Enum.Font.GothamMedium
			__label.TextXAlignment = Enum.TextXAlignment.Left
			__label.ZIndex = 4
			__label.Parent = __frame

			local __count : TextLabel = Instance.new('TextLabel')
			__count.Name = 'Count'
			__count.Size = UDim2.new(0, 120, 0, 22)
			__count.Position = UDim2.new(1, -130, 0, 6)
			__count.BackgroundTransparency = 1
			__count.Text = '0 chars'
			__count.TextColor3 = Color3.fromRGB(100, 100, 100)
			__count.TextSize = 11
			__count.Font = Enum.Font.Gotham
			__count.TextXAlignment = Enum.TextXAlignment.Right
			__count.ZIndex = 4
			__count.Parent = __frame

			local __box_holder : Frame = Instance.new('Frame')
			__box_holder.Size = UDim2.new(1, -20, 1, -38)
			__box_holder.Position = UDim2.new(0, 10, 0, 30)
			__box_holder.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
			__box_holder.BackgroundTransparency = 0.2
			__box_holder.BorderSizePixel = 0
			__box_holder.ClipsDescendants = true
			__box_holder.ZIndex = 4
			__box_holder.Parent = __frame
			__create_round(__box_holder, 6)
			__create_outline(__box_holder)

			local __scroll : ScrollingFrame = Instance.new('ScrollingFrame')
			__scroll.Size = UDim2.new(1, -8, 1, -8)
			__scroll.Position = UDim2.new(0, 4, 0, 4)
			__scroll.BackgroundTransparency = 1
			__scroll.BorderSizePixel = 0
			__scroll.ScrollBarThickness = 4
			__scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
			__scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			__scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			__scroll.ClipsDescendants = true
			__scroll.ZIndex = 5
			__scroll.Parent = __box_holder

			local __textbox : TextBox = Instance.new('TextBox')
			__textbox.Size = UDim2.new(1, -8, 0, 0)
			__textbox.AutomaticSize = Enum.AutomaticSize.Y
			__textbox.Position = UDim2.new(0, 4, 0, 0)
			__textbox.BackgroundTransparency = 1
			__textbox.Text = ''
			__textbox.PlaceholderText = __index.placeholder or 'paste here…'
			__textbox.TextColor3 = Color3.fromRGB(220, 220, 220)
			__textbox.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
			__textbox.TextSize = 12
			__textbox.Font = Enum.Font.Code
			__textbox.TextXAlignment = Enum.TextXAlignment.Left
			__textbox.TextYAlignment = Enum.TextYAlignment.Top
			__textbox.TextWrapped = true
			__textbox.MultiLine = true
			__textbox.ClearTextOnFocus = false
			__textbox.ClipsDescendants = true
			__textbox.ZIndex = 6
			__textbox.Parent = __scroll

			local function __refresh_count()
				local __n = #__textbox.Text
				local __lines = 1

				for _ in string.gmatch(__textbox.Text, '\n') do
					__lines += 1
				end

				__count.Text = tostring(__n) .. ' chars · ' .. tostring(__lines) .. ' ln'
			end

			__textbox:GetPropertyChangedSignal('Text'):Connect(function()
				__refresh_count()

				if __on_change then
					pcall(__on_change, __textbox.Text)
				end
			end)

			table.insert(self.__library.__all_elements, { name = __title, frame = __frame })

			return {
				Set = function(_, __new_text: string)
					__textbox.Text = __new_text or ''
					__refresh_count()
				end,
				Get = function()
					return __textbox.Text
				end,
				Clear = function()
					__textbox.Text = ''
					__refresh_count()
				end,
			}
		end

		function __tab:create_module(__index : { title: string, default: boolean?, callback: (state: boolean) -> () }) : Module
			local __module : Module = {}

			__module.__elements = {}
			__module.__library = self.__library

			local __default : boolean = __index.default or false
			local __callback : (state: boolean) -> () = __index.callback or (function() end)
			local __toggled : boolean = __default
			local __current_keybind : Enum.KeyCode? = nil
			local __waiting_for_key : boolean = false

			local __module_frame : Frame = Instance.new('Frame')
			__module_frame.Name = 'Module'
			__module_frame.Size = UDim2.new(1, 2, 0, 40)
			__module_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__module_frame.BackgroundTransparency = 0.3
			__module_frame.BorderSizePixel = 0
			__module_frame.ClipsDescendants = false
			__module_frame.ZIndex = 3
			__module_frame.Parent = __container
			__create_round(__module_frame, 8)
			__create_outline(__module_frame)

			local __label : TextLabel = Instance.new('TextLabel')
			__label.Size = UDim2.new(1, -110, 0, 40)
			__label.Position = UDim2.new(0, 15, 0, 0)
			__label.BackgroundTransparency = 1
			__label.Text = __index.title
			__label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__label.TextSize = 15
			__label.Font = Enum.Font.Gotham
			__label.TextXAlignment = Enum.TextXAlignment.Left
			__label.ZIndex = 4
			__label.Parent = __module_frame

			local __keybind_btn : TextButton = Instance.new('TextButton')
			__keybind_btn.Size = UDim2.new(0, 30, 0, 24)
			__keybind_btn.Position = UDim2.new(1, -90, 0, 8)
			__keybind_btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			__keybind_btn.BorderSizePixel = 0
			__keybind_btn.Text = ''
			__keybind_btn.ZIndex = 5
			__keybind_btn.Parent = __module_frame
			__create_round(__keybind_btn, 6)
			__create_outline(__keybind_btn)

			local __keybind_icon : ImageLabel = Instance.new('ImageLabel')
			__keybind_icon.Size = UDim2.new(0, 16, 0, 16)
			__keybind_icon.Position = UDim2.new(0.5, -8, 0.5, -8)
			__keybind_icon.BackgroundTransparency = 1
			__keybind_icon.Image = 'rbxassetid://10709818996'
			__keybind_icon.ImageColor3 = Color3.fromRGB(120, 120, 120)
			__keybind_icon.ZIndex = 6
			__keybind_icon.Parent = __keybind_btn

			local __keybind_label : TextLabel = Instance.new('TextLabel')
			__keybind_label.Size = UDim2.new(1, 0, 1, 0)
			__keybind_label.BackgroundTransparency = 1
			__keybind_label.Text = ''
			__keybind_label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__keybind_label.TextSize = 10
			__keybind_label.Font = Enum.Font.GothamBold
			__keybind_label.ZIndex = 7
			__keybind_label.Parent = __keybind_btn

			local __toggle_frame : Frame = Instance.new('Frame')
			__toggle_frame.Size = UDim2.new(0, 45, 0, 24)
			__toggle_frame.Position = UDim2.new(1, -55, 0, 8)
			__toggle_frame.BackgroundColor3 = __toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
			__toggle_frame.BorderSizePixel = 0
			__toggle_frame.ZIndex = 4
			__toggle_frame.Parent = __module_frame
			__create_round(__toggle_frame, 12)
			__create_outline(__toggle_frame)

			local __toggle_circle : Frame = Instance.new('Frame')
			__toggle_circle.Size = UDim2.new(0, 18, 0, 18)
			__toggle_circle.Position = __toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
			__toggle_circle.BackgroundColor3 = __toggled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
			__toggle_circle.BorderSizePixel = 0
			__toggle_circle.ZIndex = 5
			__toggle_circle.Parent = __toggle_frame
			__create_round(__toggle_circle, 9)

			local __button : TextButton = Instance.new('TextButton')
			__button.Size = UDim2.new(1, -100, 0, 40)
			__button.BackgroundTransparency = 1
			__button.Text = ''
			__button.ZIndex = 5
			__button.Parent = __module_frame

			local __toggle_button : TextButton = Instance.new('TextButton')
			__toggle_button.Size = UDim2.new(0, 45, 0, 24)
			__toggle_button.Position = UDim2.new(1, -55, 0, 8)
			__toggle_button.BackgroundTransparency = 1
			__toggle_button.Text = ''
			__toggle_button.ZIndex = 6
			__toggle_button.Parent = __module_frame

			local __module_separator : Frame = Instance.new('Frame')
			__module_separator.Size = UDim2.new(1, -20, 0, 1)
			__module_separator.Position = UDim2.new(0, 10, 0, 40)
			__module_separator.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			__module_separator.BorderSizePixel = 0
			__module_separator.ZIndex = 4
			__module_separator.Visible = false
			__module_separator.Parent = __module_frame

			local __module_container : Frame = Instance.new('Frame')
			__module_container.Size = UDim2.new(1, 0, 0, 0)
			__module_container.Position = UDim2.new(0, 0, 0, 45)
			__module_container.BackgroundTransparency = 1
			__module_container.Visible = false
			__module_container.ZIndex = 4
			__module_container.Parent = __module_frame

			local __module_padding : UIPadding = Instance.new('UIPadding')
			__module_padding.PaddingLeft = UDim.new(0, 10)
			__module_padding.PaddingRight = UDim.new(0, 10)
			__module_padding.PaddingTop = UDim.new(0, 1)
			__module_padding.Parent = __module_container

			local __module_layout : UIListLayout = Instance.new('UIListLayout')
			__module_layout.Padding = UDim.new(0, 5)
			__module_layout.SortOrder = Enum.SortOrder.LayoutOrder
			__module_layout.Parent = __module_container

			local function __update_module_height()
				local __total_height : number = 40

				for _, __elem in pairs(__module.__elements) do
					__total_height += __elem.Size.Y.Offset + 5
				end

				__create_tween(__module_frame, {Size = UDim2.new(1, 2, 0, __total_height + 10)}, 0.3)
			end

			local function __toggle_module(__state : boolean)
				if __toggled == __state then
					return
				end

				__toggled = __state

				__create_tween(__toggle_frame, {BackgroundColor3 = __toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)}, 0.3)
				__create_tween(__toggle_circle, {
					Position = __toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
					BackgroundColor3 = __toggled and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
				}, 0.3)

				if __toggled and #__module.__elements > 0 then
					__module_separator.Visible = true
					__module_container.Visible = true

					__update_module_height()
				elseif not __toggled then
					__create_tween(__module_frame, {Size = UDim2.new(1, 2, 0, 40)}, 0.3)

					__module_separator.Visible = false
					__module_container.Visible = false
				end

				__callback(__toggled)
			end

			__keybind_btn.MouseButton1Click:Connect(function()
				if __waiting_for_key then
					__waiting_for_key = false
					__keybind_label.Text = __current_keybind and __current_keybind.Name or ''

					__create_tween(__keybind_icon, {ImageTransparency = __current_keybind and 1 or 0}, 0.2)

					return
				end

				__waiting_for_key = true
				__keybind_label.Text = '...'

				__create_tween(__keybind_icon, {ImageTransparency = 1}, 0.2)

				local __connection
				__connection = UserInputService.InputBegan:Connect(function(__input, __process)
					if __process then
						return
					end

					if __input.UserInputType ~= Enum.UserInputType.Keyboard then
						return
					end

					__waiting_for_key = false
					__current_keybind = __input.KeyCode
					__keybind_label.Text = __input.KeyCode.Name
					__keybind_icon.ImageTransparency = 1

					__connection:Disconnect()
				end)
			end)

			UserInputService.InputBegan:Connect(function(__input, __process)
				if __process or __waiting_for_key then
					return
				end

				if __current_keybind and __input.KeyCode == __current_keybind then
					__toggle_module(not __toggled)
				end
			end)

			__button.MouseButton1Click:Connect(function()
				__toggle_module(not __toggled)
			end)

			__toggle_button.MouseButton1Click:Connect(function()
				__toggle_module(not __toggled)
			end)

			function __module:create_checkbox(__index : { title: string, default: boolean?, callback: (state: boolean) -> () })
				local __item_default : boolean = __index.default or false
				local __item_callback : (state: boolean) -> () = __index.callback or (function() end)

				local __item_toggled : boolean = __item_default

				local __item_frame : Frame = Instance.new('Frame')
				__item_frame.Size = UDim2.new(1, 0, 0, 35)
				__item_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__item_frame.BackgroundTransparency = 0.2
				__item_frame.BorderSizePixel = 0
				__item_frame.ZIndex = 4
				__item_frame.Parent = __module_container
				__create_round(__item_frame, 6)
				__create_outline(__item_frame)

				local __item_label : TextLabel = Instance.new('TextLabel')
				__item_label.Size = UDim2.new(1, -60, 1, 0)
				__item_label.Position = UDim2.new(0, 15, 0, 0)
				__item_label.BackgroundTransparency = 1
				__item_label.Text = __index.title
				__item_label.TextColor3 = Color3.fromRGB(120, 120, 120)
				__item_label.TextSize = 13
				__item_label.Font = Enum.Font.Gotham
				__item_label.TextXAlignment = Enum.TextXAlignment.Left
				__item_label.ZIndex = 5
				__item_label.Parent = __item_frame

				local __item_check_frame : Frame = Instance.new('Frame')
				__item_check_frame.Size = UDim2.new(0, 20, 0, 20)
				__item_check_frame.Position = UDim2.new(1, -35, 0.5, -10)
				__item_check_frame.BackgroundColor3 = __item_toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
				__item_check_frame.BorderSizePixel = 0
				__item_check_frame.ZIndex = 5
				__item_check_frame.Parent = __item_frame
				__create_round(__item_check_frame, 5)
				__create_outline(__item_check_frame)

				local __item_check_icon : ImageLabel = Instance.new('ImageLabel')
				__item_check_icon.Size = UDim2.new(0, 14, 0, 14)
				__item_check_icon.Position = UDim2.new(0.5, -7, 0.5, -7)
				__item_check_icon.BackgroundTransparency = 1
				__item_check_icon.Image = 'rbxassetid://10709790644'
				__item_check_icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
				__item_check_icon.ImageTransparency = __item_toggled and 0.2 or 1
				__item_check_icon.ZIndex = 6
				__item_check_icon.Parent = __item_check_frame

				local __item_button : TextButton = Instance.new('TextButton')
				__item_button.Size = UDim2.new(1, 0, 1, 0)
				__item_button.BackgroundTransparency = 1
				__item_button.Text = ''
				__item_button.ZIndex = 6
				__item_button.Parent = __item_frame

				__item_button.MouseButton1Click:Connect(function()
					__item_toggled = not __item_toggled

					__create_tween(__item_check_frame, {BackgroundColor3 = __item_toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)}, 0.3)
					__create_tween(__item_check_icon, {ImageTransparency = __item_toggled and 0.2 or 1}, 0.3)

					__item_callback(__item_toggled)
				end)

				table.insert(__module.__elements, __item_frame)

				if __toggled then
					__update_module_height()
				end
			end

			function __module:create_divider(__text : string?)
				local __item_frame : Frame = Instance.new('Frame')
				__item_frame.Name = 'DividerItem'
				__item_frame.Size = UDim2.new(1, 9, 0, 22)
				__item_frame.BackgroundTransparency = 1
				__item_frame.BorderSizePixel = 0
				__item_frame.ZIndex = 4
				__item_frame.Parent = __module_container

				local __divider_label : TextLabel = Instance.new('TextLabel')
				__divider_label.Size = UDim2.new(1, -20, 1, 0)
				__divider_label.Position = UDim2.new(0, 5, 0, 0)
				__divider_label.BackgroundTransparency = 1
				__divider_label.Text = __text or ''
				__divider_label.TextColor3 = Color3.fromRGB(50, 50, 50)
				__divider_label.TextSize = 13
				__divider_label.Font = Enum.Font.GothamBold
				__divider_label.TextXAlignment = Enum.TextXAlignment.Left
				__divider_label.ZIndex = 5
				__divider_label.Parent = __item_frame

				table.insert(__module.__elements, __item_frame)

				if __toggled then
					__update_module_height()
				end
			end

			function __module:create_textbox(__index : { title: string, placeholder: string?, callback: (text: string) -> () }) : { Set: (self: any, text: string) -> () }
				local __item_callback : (text: string) -> () = __index.callback or (function() end)

				local __item_frame : Frame = Instance.new('Frame')
				__item_frame.Name = 'TextboxItem'
				__item_frame.Size = UDim2.new(1, 0, 0, 40)
				__item_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__item_frame.BackgroundTransparency = 0.2
				__item_frame.BorderSizePixel = 0
				__item_frame.ZIndex = 4
				__item_frame.Parent = __module_container
				__create_round(__item_frame, 6)
				__create_outline(__item_frame)

				local __label : TextLabel = Instance.new('TextLabel')
				__label.Size = UDim2.new(0, 100, 1, 0)
				__label.Position = UDim2.new(0, 15, 0, 0)
				__label.BackgroundTransparency = 1
				__label.Text = __index.title
				__label.TextColor3 = Color3.fromRGB(120, 120, 120)
				__label.TextSize = 14
				__label.Font = Enum.Font.Gotham
				__label.TextXAlignment = Enum.TextXAlignment.Left
				__label.ZIndex = 5
				__label.Parent = __item_frame

				local __input_container : Frame = Instance.new('Frame')
				__input_container.Size = UDim2.new(0, 200, 0, 28)
				__input_container.Position = UDim2.new(1, -210, 0.5, -14)
				__input_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__input_container.BackgroundTransparency = 0.4
				__input_container.BorderSizePixel = 0
				__input_container.ZIndex = 4
				__input_container.Parent = __item_frame
				__create_round(__input_container, 6)
				__create_outline(__input_container)

				local __icon_container : Frame = Instance.new('Frame')
				__icon_container.Size = UDim2.new(0, 28, 1, 0)
				__icon_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__icon_container.BackgroundTransparency = 0.6
				__icon_container.BorderSizePixel = 0
				__icon_container.ZIndex = 4
				__icon_container.Parent = __input_container
				__create_round(__icon_container, 6)

				local __input_divider : Frame = Instance.new('Frame')
				__input_divider.Size = UDim2.new(0, 1, 0.6, 0)
				__input_divider.Position = UDim2.new(0, 28, 0.2, 0)
				__input_divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				__input_divider.BorderSizePixel = 0
				__input_divider.ZIndex = 5
				__input_divider.Parent = __input_container

				local __textbox_icon : ImageLabel = Instance.new('ImageLabel')
				__textbox_icon.Size = UDim2.new(0, 16, 0, 16)
				__textbox_icon.Position = UDim2.new(0.5, -8, 0.5, -8)
				__textbox_icon.BackgroundTransparency = 1
				__textbox_icon.Image = 'rbxassetid://10723433811'
				__textbox_icon.ImageColor3 = Color3.fromRGB(120, 120, 120)
				__textbox_icon.ZIndex = 5
				__textbox_icon.Parent = __icon_container

				local __textbox : TextBox = Instance.new('TextBox')
				__textbox.Size = UDim2.new(1, -35, 1, 0)
				__textbox.Position = UDim2.new(0, 32, 0, 0)
				__textbox.BackgroundTransparency = 1
				__textbox.Text = ''
				__textbox.PlaceholderText = __index.placeholder or ''
				__textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
				__textbox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
				__textbox.TextSize = 13
				__textbox.Font = Enum.Font.Gotham
				__textbox.TextXAlignment = Enum.TextXAlignment.Left
				__textbox.ClearTextOnFocus = false
				__textbox.ZIndex = 5
				__textbox.Parent = __input_container

				__textbox.FocusLost:Connect(function(__enter_pressed)
					if not __enter_pressed then
						return
					end

					__item_callback(__textbox.Text)
				end)

				table.insert(__module.__elements, __item_frame)

				if __toggled then
					__update_module_height()
				end

				return {
					Set = function(__self, __new_text : string)
						__textbox.Text = __new_text
					end
				}
			end

			function __module:create_slider(__index : { title: string, minimum: number?, maximum: number?, default: number?, rounding: number?, callback: (value: number) -> () }) : { Set: (self: any, value: number) -> () }
				local __min : number = __index.minimum or 0
				local __max : number = __index.maximum or 100

				local __default : number = __index.default or __min
				local __rounding : number = __index.rounding or 0

				local __item_callback : (value: number) -> () = __index.callback or (function() end)

				local __value : number = __default
				local __dragging : boolean = false

				local __item_frame : Frame = Instance.new('Frame')
				__item_frame.Name = 'SliderItem'
				__item_frame.Size = UDim2.new(1, 0, 0, 50)
				__item_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__item_frame.BackgroundTransparency = 0.2
				__item_frame.BorderSizePixel = 0
				__item_frame.ZIndex = 4
				__item_frame.Parent = __module_container
				__create_round(__item_frame, 8)
				__create_outline(__item_frame)

				local __label : TextLabel = Instance.new('TextLabel')
				__label.Size = UDim2.new(0.6, 0, 0, 20)
				__label.Position = UDim2.new(0, 15, 0, 8)
				__label.BackgroundTransparency = 1
				__label.Text = __index.title
				__label.TextColor3 = Color3.fromRGB(120, 120, 120)
				__label.TextSize = 14
				__label.Font = Enum.Font.Gotham
				__label.TextXAlignment = Enum.TextXAlignment.Left
				__label.ZIndex = 5
				__label.Parent = __item_frame

				local __value_label : TextLabel = Instance.new('TextLabel')
				__value_label.Size = UDim2.new(0.3, 0, 0, 20)
				__value_label.Position = UDim2.new(0.7, -15, 0, 8)
				__value_label.BackgroundTransparency = 1
				__value_label.Text = tostring(__value)
				__value_label.TextColor3 = Color3.fromRGB(120, 120, 120)
				__value_label.TextSize = 11
				__value_label.Font = Enum.Font.GothamMedium
				__value_label.TextXAlignment = Enum.TextXAlignment.Right
				__value_label.ZIndex = 5
				__value_label.Parent = __item_frame

				local __slider_track_bg : Frame = Instance.new('Frame')
				__slider_track_bg.Size = UDim2.new(1, -30, 0, 4)
				__slider_track_bg.Position = UDim2.new(0, 15, 1, -18)
				__slider_track_bg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				__slider_track_bg.BorderSizePixel = 0
				__slider_track_bg.ZIndex = 4
				__slider_track_bg.Parent = __item_frame
				__create_round(__slider_track_bg, 2)

				local __slider_hitbox : Frame = Instance.new('Frame')
				__slider_hitbox.Size = UDim2.new(1, 0, 0, 20)
				__slider_hitbox.Position = UDim2.new(0, 0, 0.5, -10)
				__slider_hitbox.BackgroundTransparency = 1
				__slider_hitbox.ZIndex = 7
				__slider_hitbox.Parent = __slider_track_bg

				local __slider_track : Frame = Instance.new('Frame')
				__slider_track.Size = UDim2.new(0, 0, 1, 0)
				__slider_track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				__slider_track.BorderSizePixel = 0
				__slider_track.ZIndex = 5
				__slider_track.Parent = __slider_track_bg
				__create_round(__slider_track, 2)

				local __slider_ball : Frame = Instance.new('Frame')
				__slider_ball.Size = UDim2.new(0, 10, 0, 10)
				__slider_ball.Position = UDim2.new(1, -5, 0.5, -5)
				__slider_ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				__slider_ball.BorderSizePixel = 0
				__slider_ball.ZIndex = 6
				__slider_ball.Parent = __slider_track
				__create_round(__slider_ball, 5)
				__create_outline(__slider_ball)

				local function __update_slider(__input : InputObject)
					local __position : number = math.clamp((__input.Position.X - __slider_track_bg.AbsolutePosition.X) / __slider_track_bg.AbsoluteSize.X, 0, 1)

					__value = math.floor(__min + (__max - __min) * __position)

					if __rounding > 0 then
						__value = math.floor(__value / __rounding) * __rounding
					end

					__value = math.clamp(__value, __min, __max)
					__value_label.Text = tostring(__value)

					__create_tween(__slider_track, {Size = UDim2.new(__position, 0, 1, 0)}, 0.1)

					__item_callback(__value)
				end

				local function __set_value(__new_value : number)
					__value = math.clamp(__new_value, __min, __max)

					if __rounding > 0 then
						__value = math.floor(__value / __rounding) * __rounding
					end

					__value_label.Text = tostring(__value)
					__slider_track.Size = UDim2.new((__value - __min) / (__max - __min), 0, 1, 0)

					__item_callback(__value)
				end

				__set_value(__default)

				__slider_hitbox.InputBegan:Connect(function(__input)
					if __input.UserInputType ~= Enum.UserInputType.MouseButton1 and __input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					__dragging = true

					__create_tween(__slider_ball, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6)}, 0.2)
					__update_slider(__input)
				end)

				__slider_hitbox.InputEnded:Connect(function(__input)
					if __input.UserInputType ~= Enum.UserInputType.MouseButton1 and __input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					__dragging = false

					__create_tween(__slider_ball, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -5, 0.5, -5)}, 0.2)
				end)

				UserInputService.InputChanged:Connect(function(__input)
					if not __dragging or (__input.UserInputType ~= Enum.UserInputType.MouseMovement and __input.UserInputType ~= Enum.UserInputType.Touch) then
						return
					end

					__update_slider(__input)
				end)

				table.insert(__module.__elements, __item_frame)

				if __toggled then
					__update_module_height()
				end

				return {
					Set = function(__self, __new_value : number)
						__set_value(__new_value)
					end
				}
			end

			function __module:create_button(__index : { title: string, callback: () -> () })
				local __item_callback : () -> () = __index.callback or (function() end)

				local __item_frame : Frame = Instance.new('Frame')
				__item_frame.Name = 'ButtonItem'
				__item_frame.Size = UDim2.new(1, 0, 0, 35)
				__item_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__item_frame.BackgroundTransparency = 0.2
				__item_frame.BorderSizePixel = 0
				__item_frame.ZIndex = 4
				__item_frame.Parent = __module_container
				__create_round(__item_frame, 6)
				__create_outline(__item_frame)

				local __icon : ImageLabel = Instance.new('ImageLabel')
				__icon.Size = UDim2.new(0, 18, 0, 18)
				__icon.Position = UDim2.new(1, -35, 0.5, -9)
				__icon.BackgroundTransparency = 1
				__icon.Image = 'rbxassetid://10709791437'
				__icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
				__icon.ZIndex = 5
				__icon.Parent = __item_frame

				local __label : TextLabel = Instance.new('TextLabel')
				__label.Size = UDim2.new(1, -60, 1, 0)
				__label.Position = UDim2.new(0, 15, 0, 0)
				__label.BackgroundTransparency = 1
				__label.Text = __index.title
				__label.TextColor3 = Color3.fromRGB(120, 120, 120)
				__label.TextSize = 13
				__label.Font = Enum.Font.Gotham
				__label.TextXAlignment = Enum.TextXAlignment.Left
				__label.ZIndex = 5
				__label.Parent = __item_frame

				local __button : TextButton = Instance.new('TextButton')
				__button.Size = UDim2.new(1, 0, 1, 0)
				__button.BackgroundTransparency = 1
				__button.Text = ''
				__button.ZIndex = 6
				__button.Parent = __item_frame

				__button.MouseButton1Click:Connect(function()
					__create_tween(__item_frame, {BackgroundColor3 = Color3.fromRGB(15, 15, 15)}, 0.1)

					task.delay(0.12, function()
						__create_tween(__item_frame, {BackgroundColor3 = Color3.fromRGB(8, 8, 8)}, 0.2)
					end)

					__item_callback()
				end)

				table.insert(__module.__elements, __item_frame)

				if __toggled then
					__update_module_height()
				end
			end

			function __module:create_dropdown(__index : { title: string, options: { string }, default: string | { string }?, multi_selection: boolean?, callback: (value: string | { string }) -> () }) : { Set: (self: any, value: string | { string }) -> () }
				local __options_list : { string } = __index.options or {}

				local __default_value : string | { string } = __index.default or '--'
				local __multi_selection : boolean = __index.multi_selection or false

				local __item_callback : (value: string | { string }) -> () = __index.callback or (function() end)

				local __selected : string | { string } = {}

				if not __multi_selection then
					__selected = (__default_value ~= '--' and __default_value :: string) or __options_list[1]
				else
					__selected = (type(__default_value) == 'table' and __default_value :: { string }) or {}
				end

				local __opened : boolean = false
				local __is_animating : boolean = false

				local __item_frame : Frame = Instance.new('Frame')
				__item_frame.Name = 'DropdownItem'
				__item_frame.Size = UDim2.new(1, 0, 0, 35)
				__item_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__item_frame.BackgroundTransparency = 0.2
				__item_frame.BorderSizePixel = 0
				__item_frame.ClipsDescendants = false
				__item_frame.ZIndex = 4
				__item_frame.Parent = __module_container
				__create_round(__item_frame, 6)
				__create_outline(__item_frame)

				local __item_label : TextLabel = Instance.new('TextLabel')
				__item_label.Size = UDim2.new(0.5, 0, 1, 0)
				__item_label.Position = UDim2.new(0, 15, 0, 0)
				__item_label.BackgroundTransparency = 1
				__item_label.Text = __index.title
				__item_label.TextColor3 = Color3.fromRGB(120, 120, 120)
				__item_label.TextSize = 13
				__item_label.Font = Enum.Font.Gotham
				__item_label.TextXAlignment = Enum.TextXAlignment.Left
				__item_label.ZIndex = 5
				__item_label.Parent = __item_frame

				local __dropdown_container : Frame = Instance.new('Frame')
				__dropdown_container.Size = UDim2.new(0, 135, 0, 24)
				__dropdown_container.Position = UDim2.new(1, -145, 0.5, -12)
				__dropdown_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__dropdown_container.BackgroundTransparency = 0
				__dropdown_container.BorderSizePixel = 0
				__dropdown_container.ClipsDescendants = true
				__dropdown_container.ZIndex = 15
				__dropdown_container.Parent = __item_frame
				__create_round(__dropdown_container, 6)
				__create_outline(__dropdown_container)

				local function __get_display_text() : string
					if __multi_selection then
						if #(__selected :: { string }) == 0 then
							return '--'
						end

						return table.concat(__selected :: { string }, ', ')
					else
						return __selected :: string
					end
				end

				local __icon_container : Frame = Instance.new('Frame')
				__icon_container.Size = UDim2.new(0, 24, 0, 24)
				__icon_container.Position = UDim2.new(1, -24, 0, 0)
				__icon_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__icon_container.BackgroundTransparency = 0.6
				__icon_container.BorderSizePixel = 0
				__icon_container.ZIndex = 16
				__icon_container.Parent = __dropdown_container
				__create_round(__icon_container, 6)

				local __arrow : ImageLabel = Instance.new('ImageLabel')
				__arrow.Size = UDim2.new(0, 12, 0, 12)
				__arrow.Position = UDim2.new(0.5, -6, 0.5, -6)
				__arrow.BackgroundTransparency = 1
				__arrow.Image = 'rbxassetid://10709790948'
				__arrow.ImageColor3 = Color3.fromRGB(120, 120, 120)
				__arrow.Rotation = 0
				__arrow.ZIndex = 17
				__arrow.Parent = __icon_container

				local __input_divider : Frame = Instance.new('Frame')
				__input_divider.Size = UDim2.new(0, 1, 0, 14)
				__input_divider.Position = UDim2.new(1, -25, 0, 5)
				__input_divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				__input_divider.BorderSizePixel = 0
				__input_divider.ZIndex = 17
				__input_divider.Parent = __dropdown_container

				local __selected_label : TextLabel = Instance.new('TextLabel')
				__selected_label.Size = UDim2.new(1, -30, 0, 24)
				__selected_label.Position = UDim2.new(0, 8, 0, 0)
				__selected_label.BackgroundTransparency = 1
				__selected_label.Text = __get_display_text()
				__selected_label.TextColor3 = Color3.fromRGB(255, 255, 255)
				__selected_label.TextSize = 11
				__selected_label.Font = Enum.Font.Gotham
				__selected_label.TextXAlignment = Enum.TextXAlignment.Left
				__selected_label.TextTruncate = Enum.TextTruncate.None
				__selected_label.ClipsDescendants = true
				__selected_label.ZIndex = 16
				__selected_label.Parent = __dropdown_container

				local __fade_gradient : UIGradient = Instance.new('UIGradient')
				__fade_gradient.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
				}
				__fade_gradient.Transparency = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(0.75, 0.4),
					NumberSequenceKeypoint.new(0.85, 0.7),
					NumberSequenceKeypoint.new(0.95, 0.9),
					NumberSequenceKeypoint.new(1, 1)
				}
				__fade_gradient.Parent = __selected_label

				local __dropdown_search_container : Frame = Instance.new('Frame')
				__dropdown_search_container.Size = UDim2.new(1, -10, 0, 26)
				__dropdown_search_container.Position = UDim2.new(0, 5, 0, 26)
				__dropdown_search_container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				__dropdown_search_container.BorderSizePixel = 0
				__dropdown_search_container.Visible = false
				__dropdown_search_container.ZIndex = 17
				__dropdown_search_container.Parent = __dropdown_container
				__create_round(__dropdown_search_container, 5)

				local __dropdown_search_icon_container : Frame = Instance.new('Frame')
				__dropdown_search_icon_container.Size = UDim2.new(0, 26, 1, 0)
				__dropdown_search_icon_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
				__dropdown_search_icon_container.BackgroundTransparency = 0.5
				__dropdown_search_icon_container.BorderSizePixel = 0
				__dropdown_search_icon_container.ZIndex = 17
				__dropdown_search_icon_container.Parent = __dropdown_search_container
				__create_round(__dropdown_search_icon_container, 5)

				local __dropdown_search_divider : Frame = Instance.new('Frame')
				__dropdown_search_divider.Size = UDim2.new(0, 1, 0.6, 0)
				__dropdown_search_divider.Position = UDim2.new(0, 26, 0.2, 0)
				__dropdown_search_divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				__dropdown_search_divider.BorderSizePixel = 0
				__dropdown_search_divider.ZIndex = 18
				__dropdown_search_divider.Parent = __dropdown_search_container

				local __dropdown_search_icon : ImageLabel = Instance.new('ImageLabel')
				__dropdown_search_icon.Size = UDim2.new(0, 12, 0, 12)
				__dropdown_search_icon.Position = UDim2.new(0.5, -6, 0.5, -6)
				__dropdown_search_icon.BackgroundTransparency = 1
				__dropdown_search_icon.Image = 'rbxassetid://10734943674'
				__dropdown_search_icon.ImageColor3 = Color3.fromRGB(120, 120, 120)
				__dropdown_search_icon.ZIndex = 18
				__dropdown_search_icon.Parent = __dropdown_search_icon_container

				local __dropdown_search : TextBox = Instance.new('TextBox')
				__dropdown_search.Size = UDim2.new(1, -30, 1, 0)
				__dropdown_search.Position = UDim2.new(0, 29, 0, 0)
				__dropdown_search.BackgroundTransparency = 1
				__dropdown_search.Text = ''
				__dropdown_search.PlaceholderText = 'Search'
				__dropdown_search.TextColor3 = Color3.fromRGB(255, 255, 255)
				__dropdown_search.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
				__dropdown_search.TextSize = 10
				__dropdown_search.Font = Enum.Font.Gotham
				__dropdown_search.TextXAlignment = Enum.TextXAlignment.Left
				__dropdown_search.ClearTextOnFocus = false
				__dropdown_search.ZIndex = 18
				__dropdown_search.Parent = __dropdown_search_container

				local __options_container : ScrollingFrame = Instance.new('ScrollingFrame')
				__options_container.Size = UDim2.new(1, 0, 0, 0)
				__options_container.Position = UDim2.new(0, 0, 0, 54)
				__options_container.BackgroundTransparency = 1
				__options_container.BorderSizePixel = 0
				__options_container.ScrollBarThickness = 2
				__options_container.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
				__options_container.CanvasSize = UDim2.new(0, 0, 0, 0)
				__options_container.ZIndex = 17
				__options_container.Parent = __dropdown_container

				local __options_padding : UIPadding = Instance.new('UIPadding')
				__options_padding.PaddingLeft = UDim.new(0, 5)
				__options_padding.PaddingRight = UDim.new(0, 5)
				__options_padding.Parent = __options_container

				local __options_layout : UIListLayout = Instance.new('UIListLayout')
				__options_layout.SortOrder = Enum.SortOrder.LayoutOrder
				__options_layout.Padding = UDim.new(0, 2)
				__options_layout.Parent = __options_container

				__options_layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
					__options_container.CanvasSize = UDim2.new(0, 0, 0, __options_layout.AbsoluteContentSize.Y)
				end)

				local function __close_dropdown(__instant : boolean)
					if not __opened then
						return
					end

					__opened = false
					__is_animating = false

					__dropdown_search_container.Visible = false
					__options_container.Size = UDim2.new(1, 0, 0, 0)
					__dropdown_search.Text = ''

					if __instant then
						__dropdown_container.Size = UDim2.new(0, 135, 0, 24)
						__arrow.Rotation = 0
						__item_frame.ZIndex = 4
						__dropdown_container.ZIndex = 15
						__dropdown_container.ClipsDescendants = true
						__item_label.ZIndex = 5
						__selected_label.ZIndex = 16
						__icon_container.ZIndex = 16
						__arrow.ZIndex = 17
						__input_divider.ZIndex = 17
						__dropdown_container.Parent = __item_frame
						__dropdown_container.Position = UDim2.new(1, -145, 0.5, -12)
					else
						__is_animating = true

						__create_tween(__dropdown_container, {Size = UDim2.new(0, 135, 0, 24)}, 0.3)
						__create_tween(__arrow, {Rotation = 0}, 0.3)

						task.wait(0.3)

						__item_frame.ZIndex = 4
						__dropdown_container.ZIndex = 15
						__dropdown_container.ClipsDescendants = true
						__item_label.ZIndex = 5
						__selected_label.ZIndex = 16
						__icon_container.ZIndex = 16
						__arrow.ZIndex = 17
						__input_divider.ZIndex = 17
						__dropdown_container.Parent = __item_frame
						__dropdown_container.Position = UDim2.new(1, -145, 0.5, -12)

						__is_animating = false
					end
				end

				__container:GetPropertyChangedSignal('Visible'):Connect(function()
					if not __container.Visible and __opened then
						__close_dropdown(true)
					end
				end)

				__container:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
					if __opened then
						__close_dropdown(true)
					end
				end)

				__module_container:GetPropertyChangedSignal('Visible'):Connect(function()
					if not __module_container.Visible and __opened then
						__close_dropdown(true)
					end
				end)

				local function __create_option(__option : string)
					local __is_selected : boolean = false

					if __multi_selection then
						__is_selected = table.find(__selected :: { string }, __option) ~= nil
					else
						__is_selected = __selected == __option
					end

					local __option_button : TextButton = Instance.new('TextButton')
					__option_button.Size = UDim2.new(1, 0, 0, 35)
					__option_button.BackgroundColor3 = __is_selected and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(8, 8, 8)
					__option_button.BackgroundTransparency = 0.2
					__option_button.BorderSizePixel = 0
					__option_button.Text = ''
					__option_button.AutoButtonColor = false
					__option_button.ZIndex = 18
					__option_button.Parent = __options_container
					__create_round(__option_button, 5)

					local __option_highlight : Frame = Instance.new('Frame')
					__option_highlight.Size = UDim2.new(0, 2, 0.6, 0)
					__option_highlight.Position = UDim2.new(0, 1, 0.2, 0)
					__option_highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					__option_highlight.BackgroundTransparency = __is_selected and 0.1 or 1
					__option_highlight.BorderSizePixel = 0
					__option_highlight.ZIndex = 19
					__option_highlight.Parent = __option_button
					__create_round(__option_highlight, 1)

					local __option_label : TextLabel = Instance.new('TextLabel')
					__option_label.Size = UDim2.new(1, -10, 1, 0)
					__option_label.Position = UDim2.new(0, 8, 0, 0)
					__option_label.BackgroundTransparency = 1
					__option_label.Text = __option
					__option_label.TextColor3 = __is_selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
					__option_label.TextSize = 13
					__option_label.Font = Enum.Font.GothamMedium
					__option_label.TextXAlignment = Enum.TextXAlignment.Left
					__option_label.ZIndex = 19
					__option_label.Parent = __option_button

					local __option_highlight_effect : Frame = Instance.new('Frame')
					__option_highlight_effect.Size = UDim2.new(1, 0, 1, 0)
					__option_highlight_effect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					__option_highlight_effect.BackgroundTransparency = 1
					__option_highlight_effect.BorderSizePixel = 0
					__option_highlight_effect.ZIndex = 17
					__option_highlight_effect.Parent = __option_button
					__create_round(__option_highlight_effect, 5)

					__option_button.MouseButton1Click:Connect(function()
						__option_highlight_effect.BackgroundTransparency = 1

						__create_tween(__option_highlight_effect, {BackgroundTransparency = 0.92}, 0.3)

						task.delay(0.3, function()
							__create_tween(__option_highlight_effect, {BackgroundTransparency = 1}, 0.3)
						end)

						if __multi_selection then
							local __idx = table.find(__selected :: { string }, __option)

							if __idx then
								table.remove(__selected :: { string }, __idx)

								__is_selected = false

								__create_tween(__option_button, {BackgroundColor3 = Color3.fromRGB(8, 8, 8), BackgroundTransparency = 0.2}, 0.2)
								__create_tween(__option_label, {TextColor3 = Color3.fromRGB(120, 120, 120)}, 0.2)
								__create_tween(__option_highlight, {BackgroundTransparency = 1}, 0.3)
							else
								table.insert(__selected :: { string }, __option)

								__is_selected = true

								__create_tween(__option_button, {BackgroundColor3 = Color3.fromRGB(20, 20, 20), BackgroundTransparency = 0.2}, 0.2)
								__create_tween(__option_label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
								__create_tween(__option_highlight, {BackgroundTransparency = 0.1}, 0.3)
							end

							__selected_label.Text = __get_display_text()

							__item_callback(__selected)
						else
							for _, __child in pairs(__options_container:GetChildren()) do
								if not __child:IsA('TextButton') then
									continue
								end

								local __child_highlight = __child:FindFirstChildOfClass('Frame')
								local __child_label = __child:FindFirstChildOfClass('TextLabel')

								if __child ~= __option_button then
									__create_tween(__child, {BackgroundColor3 = Color3.fromRGB(8, 8, 8), BackgroundTransparency = 0.2}, 0.2)

									if __child_label then
										__create_tween(__child_label, {TextColor3 = Color3.fromRGB(120, 120, 120)}, 0.2)
									end

									if __child_highlight then
										__create_tween(__child_highlight, {BackgroundTransparency = 1}, 0.3)
									end
								end
							end

							__selected = __option
							__is_selected = true
							__selected_label.Text = __option

							__create_tween(__option_button, {BackgroundColor3 = Color3.fromRGB(20, 20, 20), BackgroundTransparency = 0.2}, 0.2)
							__create_tween(__option_label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
							__create_tween(__option_highlight, {BackgroundTransparency = 0.1}, 0.3)

							__item_callback(__option)
						end
					end)

					return __option_button
				end

				for _, __option in ipairs(__options_list) do
					__create_option(__option)
				end

				__dropdown_search:GetPropertyChangedSignal('Text'):Connect(function()
					local __search_text : string = __dropdown_search.Text:lower()

					for _, __child in pairs(__options_container:GetChildren()) do
						if not __child:IsA('TextButton') then
							continue
						end

						local __label_child = __child:FindFirstChildOfClass('TextLabel')

						if __label_child then
							if __search_text == '' then
								__child.Visible = true
							else
								__child.Visible = __label_child.Text:lower():find(__search_text) ~= nil
							end
						end
					end
				end)

				local __dropdown_button : TextButton = Instance.new('TextButton')
				__dropdown_button.Size = UDim2.new(1, 0, 1, 0)
				__dropdown_button.BackgroundTransparency = 1
				__dropdown_button.Text = ''
				__dropdown_button.ZIndex = 16
				__dropdown_button.Parent = __dropdown_container

				__dropdown_button.MouseButton1Click:Connect(function()
					if __is_animating then
						return
					end

					if __opened then
						__close_dropdown(false)

						return
					end

					__is_animating = true
					__opened = true

					local __absolute_position = __dropdown_container.AbsolutePosition
					local __main_absolute_position = __main.AbsolutePosition

					__dropdown_container.Parent = __main
					__dropdown_container.Position = UDim2.new(0, __absolute_position.X - __main_absolute_position.X, 0, __absolute_position.Y - __main_absolute_position.Y)
					__dropdown_container.Size = UDim2.new(0, 135, 0, 24)

					__item_frame.ZIndex = 20
					__dropdown_container.ZIndex = 21
					__dropdown_container.ClipsDescendants = false
					__item_label.ZIndex = 22
					__selected_label.ZIndex = 23
					__icon_container.ZIndex = 23
					__arrow.ZIndex = 24
					__input_divider.ZIndex = 24

					local __actual_height : number = math.min(__options_layout.AbsoluteContentSize.Y, math.min(#__options_list * 37, 148))

					__dropdown_search_container.Visible = true
					__options_container.Size = UDim2.new(1, 0, 0, __actual_height)

					for __i, __child in pairs(__options_container:GetChildren()) do
						if not __child:IsA('TextButton') then
							continue
						end

						__child.BackgroundTransparency = 1

						local __label_child = __child:FindFirstChildOfClass('TextLabel')

						if __label_child then
							__label_child.TextTransparency = 1
						end

						task.delay(0.1 + (__i * 0.001), function()
							__create_tween(__child, {BackgroundTransparency = 0.2}, 0.2)

							if __label_child then
								__create_tween(__label_child, {TextTransparency = 0}, 0.2)
							end
						end)
					end

					__create_tween(__dropdown_container, {Size = UDim2.new(0, 135, 0, 54 + __actual_height + 6)}, 0.3)
					__create_tween(__arrow, {Rotation = 180}, 0.3)

					task.wait(0.3)

					__is_animating = false
				end)

				table.insert(__module.__elements, __item_frame)

				if __toggled then
					__update_module_height()
				end

				task.spawn(function()
					while __item_frame and __item_frame.Parent do
						task.wait()

						if __module.__library.__minimized and __opened then
							__close_dropdown(true)
						end
					end
				end)

				return {
					Set = function(__self, __option : string | { string })
						if __multi_selection then
							__selected = (type(__option) == 'table' and __option :: { string }) or {}
						else
							__selected = __option :: string
						end

						__selected_label.Text = __get_display_text()
						__item_callback(__selected)
					end
				}
			end

			table.insert(self.__library.__all_elements, {name = __index.title, frame = __module_frame})

			return __module
		end

		function __tab:create_checkbox(__index : { title: string, default: boolean?, callback: (state: boolean) -> () })
			local __default : boolean = __index.default or false

			local __callback : (state: boolean) -> () = __index.callback or (function() end)
			local __toggled : boolean = __default

			local __checkbox_frame : Frame = Instance.new('Frame')
			__checkbox_frame.Name = 'Checkbox'
			__checkbox_frame.Size = UDim2.new(1, 2, 0, 40)
			__checkbox_frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__checkbox_frame.BackgroundTransparency = 0.3
			__checkbox_frame.BorderSizePixel = 0
			__checkbox_frame.ZIndex = 3
			__checkbox_frame.Parent = __container
			__create_round(__checkbox_frame, 8)
			__create_outline(__checkbox_frame)

			local __label : TextLabel = Instance.new('TextLabel')
			__label.Size = UDim2.new(1, -60, 1, 0)
			__label.Position = UDim2.new(0, 15, 0, 0)
			__label.BackgroundTransparency = 1
			__label.Text = __index.title
			__label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__label.TextSize = 15
			__label.Font = Enum.Font.Gotham
			__label.TextXAlignment = Enum.TextXAlignment.Left
			__label.ZIndex = 4
			__label.Parent = __checkbox_frame

			local __check_frame : Frame = Instance.new('Frame')
			__check_frame.Size = UDim2.new(0, 24, 0, 24)
			__check_frame.Position = UDim2.new(1, -40, 0.5, -12)
			__check_frame.BackgroundColor3 = __toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
			__check_frame.BorderSizePixel = 0
			__check_frame.ZIndex = 4
			__check_frame.Parent = __checkbox_frame
			__create_round(__check_frame, 6)
			__create_outline(__check_frame)

			local __check_icon : ImageLabel = Instance.new('ImageLabel')
			__check_icon.Size = UDim2.new(0, 16, 0, 16)
			__check_icon.Position = UDim2.new(0.5, -8, 0.5, -8)
			__check_icon.BackgroundTransparency = 1
			__check_icon.Image = 'rbxassetid://10709790644'
			__check_icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
			__check_icon.ImageTransparency = __toggled and 0.2 or 1
			__check_icon.ZIndex = 5
			__check_icon.Parent = __check_frame

			local __button : TextButton = Instance.new('TextButton')
			__button.Size = UDim2.new(1, 0, 1, 0)
			__button.BackgroundTransparency = 1
			__button.Text = ''
			__button.ZIndex = 5
			__button.Parent = __checkbox_frame

			__button.MouseButton1Click:Connect(function()
				__toggled = not __toggled

				__create_tween(__check_frame, {BackgroundColor3 = __toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)}, 0.3)
				__create_tween(__check_icon, {ImageTransparency = __toggled and 0.2 or 1}, 0.3)

				__callback(__toggled)
			end)

			table.insert(self.__library.__all_elements, {name = __index.title, frame = __checkbox_frame})
		end

		function __tab:create_dropdown(__index : { title: string, options: { string }, default: string | { string }?, multi_selection: boolean?, callback: (value: string | { string }) -> () }) : { Set: (self: any, value: string | { string }) -> () }
			local __options_list : { string } = __index.options or {}

			local __default_value : string | { string } = __index.default or '--'
			local __multi_selection : boolean = __index.multi_selection or false

			local __callback : (value: string | { string }) -> () = __index.callback or (function() end)

			local __selected : string | { string } = {}

			if not __multi_selection then
				__selected = (__default_value ~= '--' and __default_value :: string) or __options_list[1]
			else
				__selected = (type(__default_value) == 'table' and __default_value :: { string }) or {}
			end

			local __opened : boolean = false
			local __is_animating : boolean = false

			local __dropdown : Frame = Instance.new('Frame')
			__dropdown.Name = 'Dropdown'
			__dropdown.Size = UDim2.new(1, 2, 0, 40)
			__dropdown.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__dropdown.BackgroundTransparency = 0.3
			__dropdown.BorderSizePixel = 0
			__dropdown.ZIndex = 10
			__dropdown.ClipsDescendants = false
			__dropdown.Parent = __container
			__create_round(__dropdown, 8)
			__create_outline(__dropdown)

			local __label : TextLabel = Instance.new('TextLabel')
			__label.Size = UDim2.new(0, 150, 0, 40)
			__label.Position = UDim2.new(0, 15, 0, 0)
			__label.BackgroundTransparency = 1
			__label.Text = __index.title
			__label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__label.TextSize = 15
			__label.Font = Enum.Font.Gotham
			__label.TextXAlignment = Enum.TextXAlignment.Left
			__label.ZIndex = 11
			__label.Parent = __dropdown

			local __dropdown_container : Frame = Instance.new('Frame')
			__dropdown_container.Size = UDim2.new(0, 145, 0, 28)
			__dropdown_container.Position = UDim2.new(1, -155, 0.5, -14)
			__dropdown_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__dropdown_container.BackgroundTransparency = 0
			__dropdown_container.BorderSizePixel = 0
			__dropdown_container.ClipsDescendants = true
			__dropdown_container.ZIndex = 15
			__dropdown_container.Parent = __dropdown
			__create_round(__dropdown_container, 6)
			__create_outline(__dropdown_container)

			local function __get_display_text() : string
				if __multi_selection then
					if #(__selected :: { string }) == 0 then
						return '--'
					end

					return table.concat(__selected :: { string }, ', ')
				else
					return __selected :: string
				end
			end

			local __icon_container : Frame = Instance.new('Frame')
			__icon_container.Size = UDim2.new(0, 28, 0, 28)
			__icon_container.Position = UDim2.new(1, -28, 0, 0)
			__icon_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__icon_container.BackgroundTransparency = 0.6
			__icon_container.BorderSizePixel = 0
			__icon_container.ZIndex = 16
			__icon_container.Parent = __dropdown_container
			__create_round(__icon_container, 6)

			local __arrow : ImageLabel = Instance.new('ImageLabel')
			__arrow.Size = UDim2.new(0, 12, 0, 12)
			__arrow.Position = UDim2.new(0.5, -6, 0.5, -6)
			__arrow.BackgroundTransparency = 1
			__arrow.Image = 'rbxassetid://10709790948'
			__arrow.ImageColor3 = Color3.fromRGB(120, 120, 120)
			__arrow.Rotation = 0
			__arrow.ZIndex = 17
			__arrow.Parent = __icon_container

			local __input_divider : Frame = Instance.new('Frame')
			__input_divider.Size = UDim2.new(0, 1, 0, 17)
			__input_divider.Position = UDim2.new(1, -29, 0, 6)
			__input_divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			__input_divider.BorderSizePixel = 0
			__input_divider.ZIndex = 17
			__input_divider.Parent = __dropdown_container

			local __selected_label : TextLabel = Instance.new('TextLabel')
			__selected_label.Size = UDim2.new(1, -35, 0, 28)
			__selected_label.Position = UDim2.new(0, 8, 0, 0)
			__selected_label.BackgroundTransparency = 1
			__selected_label.Text = __get_display_text()
			__selected_label.TextColor3 = Color3.fromRGB(255, 255, 255)
			__selected_label.TextSize = 12
			__selected_label.Font = Enum.Font.Gotham
			__selected_label.TextXAlignment = Enum.TextXAlignment.Left
			__selected_label.TextTruncate = Enum.TextTruncate.None
			__selected_label.ClipsDescendants = true
			__selected_label.ZIndex = 16
			__selected_label.Parent = __dropdown_container

			local __fade_gradient : UIGradient = Instance.new('UIGradient')
			__fade_gradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
			}
			__fade_gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.75, 0.4),
				NumberSequenceKeypoint.new(0.85, 0.7),
				NumberSequenceKeypoint.new(0.95, 0.9),
				NumberSequenceKeypoint.new(1, 1)
			}
			__fade_gradient.Parent = __selected_label

			local __dropdown_search_container : Frame = Instance.new('Frame')
			__dropdown_search_container.Size = UDim2.new(1, -10, 0, 26)
			__dropdown_search_container.Position = UDim2.new(0, 5, 0, 30)
			__dropdown_search_container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			__dropdown_search_container.BorderSizePixel = 0
			__dropdown_search_container.Visible = false
			__dropdown_search_container.ZIndex = 17
			__dropdown_search_container.Parent = __dropdown_container
			__create_round(__dropdown_search_container, 5)

			local __dropdown_search_icon_container : Frame = Instance.new('Frame')
			__dropdown_search_icon_container.Size = UDim2.new(0, 26, 1, 0)
			__dropdown_search_icon_container.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
			__dropdown_search_icon_container.BackgroundTransparency = 0.5
			__dropdown_search_icon_container.BorderSizePixel = 0
			__dropdown_search_icon_container.ZIndex = 17
			__dropdown_search_icon_container.Parent = __dropdown_search_container
			__create_round(__dropdown_search_icon_container, 5)

			local __dropdown_search_divider : Frame = Instance.new('Frame')
			__dropdown_search_divider.Size = UDim2.new(0, 1, 0.6, 0)
			__dropdown_search_divider.Position = UDim2.new(0, 26, 0.2, 0)
			__dropdown_search_divider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			__dropdown_search_divider.BorderSizePixel = 0
			__dropdown_search_divider.ZIndex = 18
			__dropdown_search_divider.Parent = __dropdown_search_container

			local __dropdown_search_icon : ImageLabel = Instance.new('ImageLabel')
			__dropdown_search_icon.Size = UDim2.new(0, 12, 0, 12)
			__dropdown_search_icon.Position = UDim2.new(0.5, -6, 0.5, -6)
			__dropdown_search_icon.BackgroundTransparency = 1
			__dropdown_search_icon.Image = 'rbxassetid://10734943674'
			__dropdown_search_icon.ImageColor3 = Color3.fromRGB(120, 120, 120)
			__dropdown_search_icon.ZIndex = 18
			__dropdown_search_icon.Parent = __dropdown_search_icon_container

			local __dropdown_search : TextBox = Instance.new('TextBox')
			__dropdown_search.Size = UDim2.new(1, -30, 1, 0)
			__dropdown_search.Position = UDim2.new(0, 29, 0, 0)
			__dropdown_search.BackgroundTransparency = 1
			__dropdown_search.Text = ''
			__dropdown_search.PlaceholderText = 'Search'
			__dropdown_search.TextColor3 = Color3.fromRGB(255, 255, 255)
			__dropdown_search.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
			__dropdown_search.TextSize = 10
			__dropdown_search.Font = Enum.Font.Gotham
			__dropdown_search.TextXAlignment = Enum.TextXAlignment.Left
			__dropdown_search.ClearTextOnFocus = false
			__dropdown_search.ZIndex = 18
			__dropdown_search.Parent = __dropdown_search_container

			local __options_container : ScrollingFrame = Instance.new('ScrollingFrame')
			__options_container.Size = UDim2.new(1, 0, 0, 0)
			__options_container.Position = UDim2.new(0, 0, 0, 58)
			__options_container.BackgroundTransparency = 1
			__options_container.BorderSizePixel = 0
			__options_container.ScrollBarThickness = 2
			__options_container.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
			__options_container.CanvasSize = UDim2.new(0, 0, 0, 0)
			__options_container.ZIndex = 17
			__options_container.Parent = __dropdown_container

			local __options_padding : UIPadding = Instance.new('UIPadding')
			__options_padding.PaddingLeft = UDim.new(0, 5)
			__options_padding.PaddingRight = UDim.new(0, 5)
			__options_padding.Parent = __options_container

			local __options_layout : UIListLayout = Instance.new('UIListLayout')
			__options_layout.SortOrder = Enum.SortOrder.LayoutOrder
			__options_layout.Padding = UDim.new(0, 2)
			__options_layout.Parent = __options_container

			__options_layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				__options_container.CanvasSize = UDim2.new(0, 0, 0, __options_layout.AbsoluteContentSize.Y)
			end)

			local function __close_dropdown(__instant : boolean)
				if not __opened then
					return
				end

				__opened = false
				__is_animating = false

				__dropdown_search_container.Visible = false
				__options_container.Size = UDim2.new(1, 0, 0, 0)
				__dropdown_search.Text = ''

				if __instant then
					__dropdown_container.Size = UDim2.new(0, 145, 0, 28)
					__arrow.Rotation = 0
					__dropdown.ZIndex = 10
					__dropdown_container.ZIndex = 15
					__dropdown_container.ClipsDescendants = true
					__label.ZIndex = 11
					__selected_label.ZIndex = 16
					__icon_container.ZIndex = 16
					__arrow.ZIndex = 17
					__input_divider.ZIndex = 17
					__dropdown_container.Parent = __dropdown
					__dropdown_container.Position = UDim2.new(1, -155, 0.5, -14)
				else
					__is_animating = true

					__create_tween(__dropdown_container, {Size = UDim2.new(0, 145, 0, 28)}, 0.3)
					__create_tween(__arrow, {Rotation = 0}, 0.3)

					task.wait(0.3)

					__dropdown.ZIndex = 10
					__dropdown_container.ZIndex = 15
					__dropdown_container.ClipsDescendants = true
					__label.ZIndex = 11
					__selected_label.ZIndex = 16
					__icon_container.ZIndex = 16
					__arrow.ZIndex = 17
					__input_divider.ZIndex = 17
					__dropdown_container.Parent = __dropdown
					__dropdown_container.Position = UDim2.new(1, -155, 0.5, -14)

					__is_animating = false
				end
			end

			__container:GetPropertyChangedSignal('Visible'):Connect(function()
				if not __container.Visible and __opened then
					__close_dropdown(true)
				end
			end)

			__container:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
				if __opened then
					__close_dropdown(true)
				end
			end)

			local function __create_option(__option : string)
				local __is_selected : boolean = false

				if __multi_selection then
					__is_selected = table.find(__selected :: { string }, __option) ~= nil
				else
					__is_selected = __selected == __option
				end

				local __option_button : TextButton = Instance.new('TextButton')
				__option_button.Size = UDim2.new(1, 0, 0, 35)
				__option_button.BackgroundColor3 = __is_selected and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(8, 8, 8)
				__option_button.BackgroundTransparency = 0.2
				__option_button.BorderSizePixel = 0
				__option_button.Text = ''
				__option_button.AutoButtonColor = false
				__option_button.ZIndex = 18
				__option_button.Parent = __options_container
				__create_round(__option_button, 5)

				local __option_highlight : Frame = Instance.new('Frame')
				__option_highlight.Size = UDim2.new(0, 2, 0.6, 0)
				__option_highlight.Position = UDim2.new(0, 1, 0.2, 0)
				__option_highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				__option_highlight.BackgroundTransparency = __is_selected and 0.1 or 1
				__option_highlight.BorderSizePixel = 0
				__option_highlight.ZIndex = 19
				__option_highlight.Parent = __option_button
				__create_round(__option_highlight, 1)

				local __option_label : TextLabel = Instance.new('TextLabel')
				__option_label.Size = UDim2.new(1, -10, 1, 0)
				__option_label.Position = UDim2.new(0, 8, 0, 0)
				__option_label.BackgroundTransparency = 1
				__option_label.Text = __option
				__option_label.TextColor3 = __is_selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
				__option_label.TextSize = 13
				__option_label.Font = Enum.Font.GothamMedium
				__option_label.TextXAlignment = Enum.TextXAlignment.Left
				__option_label.ZIndex = 19
				__option_label.Parent = __option_button

				local __option_highlight_effect : Frame = Instance.new('Frame')
				__option_highlight_effect.Size = UDim2.new(1, 0, 1, 0)
				__option_highlight_effect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				__option_highlight_effect.BackgroundTransparency = 1
				__option_highlight_effect.BorderSizePixel = 0
				__option_highlight_effect.ZIndex = 17
				__option_highlight_effect.Parent = __option_button
				__create_round(__option_highlight_effect, 5)

				__option_button.MouseButton1Click:Connect(function()
					__option_highlight_effect.BackgroundTransparency = 1

					__create_tween(__option_highlight_effect, {BackgroundTransparency = 0.92}, 0.3)

					task.delay(0.3, function()
						__create_tween(__option_highlight_effect, {BackgroundTransparency = 1}, 0.3)
					end)

					if __multi_selection then
						local __idx = table.find(__selected :: { string }, __option)

						if __idx then
							table.remove(__selected :: { string }, __idx)

							__is_selected = false

							__create_tween(__option_button, {BackgroundColor3 = Color3.fromRGB(8, 8, 8), BackgroundTransparency = 0.2}, 0.2)
							__create_tween(__option_label, {TextColor3 = Color3.fromRGB(120, 120, 120)}, 0.2)
							__create_tween(__option_highlight, {BackgroundTransparency = 1}, 0.3)
						else
							table.insert(__selected :: { string }, __option)

							__is_selected = true

							__create_tween(__option_button, {BackgroundColor3 = Color3.fromRGB(20, 20, 20), BackgroundTransparency = 0.2}, 0.2)
							__create_tween(__option_label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
							__create_tween(__option_highlight, {BackgroundTransparency = 0.1}, 0.3)
						end

						__selected_label.Text = __get_display_text()

						__callback(__selected)
					else
						for _, __child in pairs(__options_container:GetChildren()) do
							if not __child:IsA('TextButton') then
								continue
							end

							local __child_highlight = __child:FindFirstChildOfClass('Frame')
							local __child_label = __child:FindFirstChildOfClass('TextLabel')

							if __child ~= __option_button then
								__create_tween(__child, {BackgroundColor3 = Color3.fromRGB(8, 8, 8), BackgroundTransparency = 0.2}, 0.2)

								if __child_label then
									__create_tween(__child_label, {TextColor3 = Color3.fromRGB(120, 120, 120)}, 0.2)
								end

								if __child_highlight then
									__create_tween(__child_highlight, {BackgroundTransparency = 1}, 0.3)
								end
							end
						end

						__selected = __option
						__is_selected = true
						__selected_label.Text = __option

						__create_tween(__option_button, {BackgroundColor3 = Color3.fromRGB(20, 20, 20), BackgroundTransparency = 0.2}, 0.2)
						__create_tween(__option_label, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
						__create_tween(__option_highlight, {BackgroundTransparency = 0.1}, 0.3)

						__callback(__option)
					end
				end)

				return __option_button
			end

			for _, __option in ipairs(__options_list) do
				__create_option(__option)
			end

			__dropdown_search:GetPropertyChangedSignal('Text'):Connect(function()
				local __search_text : string = __dropdown_search.Text:lower()

				for _, __child in pairs(__options_container:GetChildren()) do
					if not __child:IsA('TextButton') then
						continue
					end

					local __label_child = __child:FindFirstChildOfClass('TextLabel')

					if __label_child then
						if __search_text == '' then
							__child.Visible = true
						else
							__child.Visible = __label_child.Text:lower():find(__search_text) ~= nil
						end
					end
				end
			end)

			local __dropdown_button : TextButton = Instance.new('TextButton')
			__dropdown_button.Size = UDim2.new(1, 0, 1, 0)
			__dropdown_button.BackgroundTransparency = 1
			__dropdown_button.Text = ''
			__dropdown_button.ZIndex = 16
			__dropdown_button.Parent = __dropdown_container

			__dropdown_button.MouseButton1Click:Connect(function()
				if __is_animating then
					return
				end

				if __opened then
					__close_dropdown(false)

					return
				end

				__is_animating = true
				__opened = true

				local __absolute_position = __dropdown_container.AbsolutePosition
				local __main_absolute_position = __main.AbsolutePosition

				__dropdown_container.Parent = __main
				__dropdown_container.Position = UDim2.new(0, __absolute_position.X - __main_absolute_position.X, 0, __absolute_position.Y - __main_absolute_position.Y)
				__dropdown_container.Size = UDim2.new(0, 145, 0, 28)

				__dropdown.ZIndex = 20
				__dropdown_container.ZIndex = 21
				__dropdown_container.ClipsDescendants = false
				__label.ZIndex = 22
				__selected_label.ZIndex = 23
				__icon_container.ZIndex = 23
				__arrow.ZIndex = 24
				__input_divider.ZIndex = 24

				local __actual_height : number = math.min(__options_layout.AbsoluteContentSize.Y, math.min(#__options_list * 37, 148))

				__dropdown_search_container.Visible = true
				__options_container.Size = UDim2.new(1, 0, 0, __actual_height)

				for __i, __child in pairs(__options_container:GetChildren()) do
					if not __child:IsA('TextButton') then
						continue
					end

					__child.BackgroundTransparency = 1

					local __label_child = __child:FindFirstChildOfClass('TextLabel')

					if __label_child then
						__label_child.TextTransparency = 1
					end

					task.delay(0.1 + (__i * 0.001), function()
						__create_tween(__child, {BackgroundTransparency = 0.2}, 0.2)

						if __label_child then
							__create_tween(__label_child, {TextTransparency = 0}, 0.2)
						end
					end)
				end

				__create_tween(__dropdown_container, {Size = UDim2.new(0, 145, 0, 58 + __actual_height + 6)}, 0.3)
				__create_tween(__arrow, {Rotation = 180}, 0.3)

				task.wait(0.3)

				__is_animating = false
			end)

			table.insert(self.__library.__all_elements, {name = __index.title, frame = __dropdown})

			task.spawn(function()
				while __dropdown and __dropdown.Parent do
					task.wait()

					if self.__library.__minimized and __opened then
						__close_dropdown(true)
					end
				end
			end)

			return {
				Set = function(__self, __option : string | { string })
					if __multi_selection then
						__selected = (type(__option) == 'table' and __option :: { string }) or {}
					else
						__selected = __option :: string
					end

					__selected_label.Text = __get_display_text()
					__callback(__selected)
				end
			}
		end

		return __tab
	end

	return self
end


export type AntiTamper = {
	__alive: boolean,
	__token: string,
	__refs: { [string]: any },
	__fn_ids: { [string]: string },
	__mods: { any },
	__mod_map: { [string]: any },
	__gui: ScreenGui?,
	__conn: RBXScriptConnection?,
	__thread: thread?,
	__trips: number,
	__max_trips: number,
	__silent: boolean,

	init: (self: AntiTamper) -> AntiTamper,
	start: (self: AntiTamper) -> (),
	register: (self: AntiTamper, name: string, mod: any) -> (),
	bind_gui: (self: AntiTamper, gui: ScreenGui) -> (),
	seal: (self: AntiTamper) -> (),
	trip: (self: AntiTamper, reason: string) -> (),
	stop: (self: AntiTamper) -> (),
	destroy: (self: AntiTamper) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local RunService = Service.RunService
local CoreGui = Service.CoreGui
local LocalPlayer = Players.LocalPlayer

local function __rand_token() : string
	local __buf = {}

	for __i = 1, 24 do
		__buf[__i] = string.char(math.random(97, 122))
	end

	return table.concat(__buf) .. tostring(os.clock() * 1e6 % 1e9)
end

local function __fn_id(__fn : any) : string
	if type(__fn) ~= 'function' then
		return 'nil'
	end

	local __ok, __info = pcall(function()
		if typeof(debug) == 'table' and type(debug.info) == 'function' then
			return tostring(debug.info(__fn, 's')) .. ':' .. tostring(debug.info(__fn, 'l')) .. ':' .. tostring(debug.info(__fn, 'n'))
		end

		return tostring(__fn)
	end)

	if __ok then
		return tostring(__info) .. '#' .. tostring(__fn)
	end

	return tostring(__fn)
end

local AntiTamper : AntiTamper = {
	__alive = false,
	__token = '',
	__refs = {},
	__fn_ids = {},
	__mods = {},
	__mod_map = {},
	__gui = nil,
	__conn = nil,
	__thread = nil,
	__trips = 0,
	__max_trips = 2,
	__silent = true,
}
AntiTamper.__index = AntiTamper

function AntiTamper:init() : AntiTamper
	self.__alive = true
	self.__token = __rand_token()
	self.__refs = {}
	self.__fn_ids = {}
	self.__mods = {}
	self.__mod_map = {}
	self.__gui = nil
	self.__trips = 0
	self.__silent = true

	self.__refs.game = game
	self.__refs.workspace = workspace
	self.__refs.typeof = typeof
	self.__refs.pcall = pcall
	self.__refs.rawget = rawget
	self.__refs.rawset = rawset
	self.__refs.rawequal = rawequal
	self.__refs.tostring = tostring
	self.__refs.type = type
	self.__refs.Instance_new = Instance.new
	self.__refs.GetService = game.GetService

	if typeof(firetouchinterest) == 'function' then
		self.__refs.firetouchinterest = firetouchinterest
		self.__fn_ids.firetouchinterest = __fn_id(firetouchinterest)
	end

	if typeof(hookmetamethod) == 'function' then
		self.__refs.hookmetamethod = hookmetamethod
		self.__fn_ids.hookmetamethod = __fn_id(hookmetamethod)
	end

	if typeof(getgenv) == 'function' then
		self.__refs.getgenv = getgenv
	end

	if typeof(gethui) == 'function' then
		self.__refs.gethui = gethui
	end

	if typeof(cloneref) == 'function' then
		self.__refs.cloneref = cloneref
		self.__fn_ids.cloneref = __fn_id(cloneref)
	end

	if typeof(getnamecallmethod) == 'function' then
		self.__refs.getnamecallmethod = getnamecallmethod
		self.__fn_ids.getnamecallmethod = __fn_id(getnamecallmethod)
	end

	if typeof(getconnections) == 'function' then
		self.__refs.getconnections = getconnections
		self.__fn_ids.getconnections = __fn_id(getconnections)
	end

	local __env_key = '__eph_' .. string.sub(self.__token, 1, 10)

	self.__refs.env_key = __env_key

	pcall(function()
		if typeof(getgenv) == 'function' then
			getgenv()[__env_key] = self.__token
		end
	end)

	return self
end

function AntiTamper:register(__name : string, __mod : any) : ()
	if type(__mod) ~= 'table' then
		return
	end

	table.insert(self.__mods, __mod)
	self.__mod_map[__name] = __mod

	local __src = __mod

	if type(__mod.__index) == 'table' then
		__src = __mod.__index
	end

	for __k, __v in pairs(__src) do
		if type(__v) == 'function' and type(__k) == 'string' and string.sub(__k, 1, 1) ~= '_' then
			local __key = __name .. '.' .. __k

			self.__fn_ids[__key] = __fn_id(__v)
			self.__refs[__key] = __v
		end
	end
end

function AntiTamper:bind_gui(__gui : ScreenGui) : ()
	if not __gui then
		return
	end

	self.__gui = __gui

	pcall(function()
		__gui:SetAttribute('__eph', self.__token)
		__gui.Name = 'Euphoria'
		__gui.ResetOnSpawn = false
	end)

	pcall(function()
		__gui.Destroying:Connect(function()
			if self.__alive and self.__gui == __gui then
				self:trip('gui_destroy')
			end
		end)
	end)

	pcall(function()
		__gui.AncestryChanged:Connect(function(_, __parent)
			if not self.__alive then
				return
			end

			if __parent == nil then
				self:trip('gui_orphaned')

				return
			end

			local __ok = false

			pcall(function()
				if __parent == CoreGui then
					__ok = true
				end

				if typeof(gethui) == 'function' and __parent == gethui() then
					__ok = true
				end
			end)

			if not __ok then
				self:trip('gui_reparent')
			end
		end)
	end)
end

function AntiTamper:seal() : ()
	if type(Library) == 'table' then
		self:register('Library', Library)

		if Library.__window and Library.__window.euphoria then
			self:bind_gui(Library.__window.euphoria)
		end
	end

	if type(AcBypass) == 'table' then
		self:register('AcBypass', AcBypass)
	end

	if type(Reach) == 'table' then
		self:register('Reach', Reach)
	end

	if type(Reacts) == 'table' then
		self:register('Reacts', Reacts)
	end

	if type(AutoHeader) == 'table' then
		self:register('AutoHeader', AutoHeader)
	end

	if type(Config) == 'table' then
		self:register('Config', Config)
	end

	if type(Console) == 'table' then
		self:register('Console', Console)
	end
end

local function __check_fn_ref(__self : AntiTamper, __key : string, __fn : any) : boolean
	local __saved = __self.__fn_ids[__key]

	if not __saved then
		return true
	end

	if type(__fn) ~= 'function' then
		return false
	end

	return __fn_id(__fn) == __saved
end

local function __integrity(__self : AntiTamper) : string?
	if not __self.__alive then
		return 'dead'
	end

	if not rawequal(typeof, __self.__refs.typeof) then
		return 'typeof_swap'
	end

	if not rawequal(pcall, __self.__refs.pcall) then
		return 'pcall_swap'
	end

	if not rawequal(rawget, __self.__refs.rawget) then
		return 'rawget_swap'
	end

	if not rawequal(Instance.new, __self.__refs.Instance_new) then
		return 'instance_new_swap'
	end

	if __self.__refs.firetouchinterest and typeof(firetouchinterest) == 'function' then
		if not rawequal(firetouchinterest, __self.__refs.firetouchinterest) then
			return 'firetouch_hook'
		end
	end

	if __self.__refs.cloneref and typeof(cloneref) == 'function' then
		if not rawequal(cloneref, __self.__refs.cloneref) then
			return 'cloneref_hook'
		end
	end

	if __self.__refs.getnamecallmethod and typeof(getnamecallmethod) == 'function' then
		if not rawequal(getnamecallmethod, __self.__refs.getnamecallmethod) then
			return 'gncm_hook'
		end
	end

	if __self.__refs.env_key and typeof(getgenv) == 'function' then
		local __ok, __val = pcall(function()
			return getgenv()[__self.__refs.env_key]
		end)

		if not __ok or __val ~= __self.__token then
			return 'env_token'
		end
	end

	if __self.__gui then
		if not __self.__gui.Parent then
			return 'gui_missing'
		end

		local __attr = nil

		pcall(function()
			__attr = __self.__gui:GetAttribute('__eph')
		end)

		if __attr ~= __self.__token then
			return 'gui_token'
		end

		for _, __child in ipairs(CoreGui:GetChildren()) do
			if __child:IsA('ScreenGui') and __child.Name == 'Euphoria' and __child ~= __self.__gui then
				local __other = nil

				pcall(function()
					__other = __child:GetAttribute('__eph')
				end)

				if __other ~= __self.__token then
					pcall(function()
						__child:Destroy()
					end)
				end
			end
		end
	end

	for __name, __mod in pairs(__self.__mod_map) do
		if type(__mod) ~= 'table' then
			return 'mod_missing_' .. __name
		end

		local __src = __mod

		if type(__mod.__index) == 'table' then
			__src = __mod.__index
		end

		for __k, __saved in pairs(__self.__refs) do
			if type(__k) == 'string' and string.sub(__k, 1, #__name + 1) == __name .. '.' then
				local __fn_name = string.sub(__k, #__name + 2)
				local __fn = __src[__fn_name]

				if type(__saved) == 'function' and type(__fn) == 'function' then
					if not rawequal(__fn, __saved) then
						return 'mod_fn_' .. __k
					end
				elseif type(__saved) == 'function' and type(__fn) ~= 'function' then
					return 'mod_fn_gone_' .. __k
				end
			end
		end
	end

	return nil
end

function AntiTamper:trip(__reason : string) : ()
	if not self.__alive then
		return
	end

	self.__trips += 1

	if not self.__silent then
		warn('[euphoria] anti-tamper: ' .. tostring(__reason))
	end

	if self.__trips < self.__max_trips and __reason ~= 'gui_destroy' and __reason ~= 'gui_orphaned' then
		return
	end

	self.__alive = false

	pcall(function()
		if type(Reach) == 'table' and type(Reach.set_enabled) == 'function' then
			Reach:set_enabled(false)
		end

		if type(Reacts) == 'table' and type(Reacts.set_enabled) == 'function' then
			Reacts:set_enabled(false)
		end

		if type(AutoHeader) == 'table' and type(AutoHeader.set_enabled) == 'function' then
			AutoHeader:set_enabled(false)
		end

		if type(Reach) == 'table' and type(Reach.stop) == 'function' then
			Reach:stop()
		end

		if type(Reacts) == 'table' and type(Reacts.stop) == 'function' then
			Reacts:stop()
		end

		if type(AutoHeader) == 'table' and type(AutoHeader.stop) == 'function' then
			AutoHeader:stop()
		end
	end)

	pcall(function()
		if self.__gui then
			self.__gui:Destroy()
		end
	end)

	pcall(function()
		local __old = CoreGui:FindFirstChild('Euphoria')

		if __old then
			__old:Destroy()
		end
	end)

	pcall(function()
		if typeof(getgenv) == 'function' and self.__refs.env_key then
			getgenv()[self.__refs.env_key] = nil
			getgenv().Library = nil
			getgenv().Reach = nil
			getgenv().Reacts = nil
			getgenv().AutoHeader = nil
			getgenv().AcBypass = nil
			getgenv().AntiTamper = nil
			getgenv().Config = nil
			getgenv().Console = nil
		end
	end)

	pcall(function()
		for __k in pairs(self.__fn_ids) do
			self.__fn_ids[__k] = nil
		end

		for __k in pairs(self.__refs) do
			self.__refs[__k] = nil
		end

		table.clear(self.__mods)
	end)

	self:stop()
end

function AntiTamper:start() : ()
	if self.__conn or self.__thread then
		return
	end

	self.__alive = true

	self.__conn = RunService.Heartbeat:Connect(function()
		if not self.__alive then
			return
		end

		if math.random(1, 4) ~= 1 then
			return
		end

		local __reason = __integrity(self)

		if __reason then
			self:trip(__reason)
		end
	end)

	self.__thread = task.spawn(function()
		while self.__alive do
			task.wait(1.25 + math.random() * 0.75)

			local __reason = __integrity(self)

			if __reason then
				self:trip(__reason)
			end

			pcall(function()
				if self.__gui and self.__gui.Parent then
					local __attr = self.__gui:GetAttribute('__eph')

					if __attr ~= self.__token then
						self.__gui:SetAttribute('__eph', self.__token)
					end
				end
			end)

			pcall(function()
				if typeof(getgenv) == 'function' and self.__refs.env_key then
					if getgenv()[self.__refs.env_key] ~= self.__token then
						getgenv()[self.__refs.env_key] = self.__token
					end
				end
			end)
		end
	end)
end

function AntiTamper:stop() : ()
	self.__alive = false

	if self.__conn then
		self.__conn:Disconnect()
		self.__conn = nil
	end

	self.__thread = nil
end

function AntiTamper:destroy() : ()
	self:trip('destroy')
end


export type AcBypass = {
	__enabled: boolean,
	__hooked: boolean,
	__old_namecall: any,
	__char_conn: RBXScriptConnection?,
	__scan_thread: thread?,

	init: (self: AcBypass) -> AcBypass,
	start: (self: AcBypass) -> (),
	stop: (self: AcBypass) -> (),
	set_enabled: (self: AcBypass, state: boolean) -> (),
	destroy: (self: AcBypass) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local LocalPlayer = Players.LocalPlayer

local AcBypass : AcBypass = {
	__enabled = true,
	__hooked = false,
	__old_namecall = nil,
	__char_conn = nil,
	__scan_thread = nil,
}
AcBypass.__index = AcBypass

local function __is_helloworld(__inst : any) : boolean
	if typeof(__inst) ~= 'Instance' then
		return false
	end

	return __inst.Name == 'HelloWorld'
end

local function __strip_size_ac(__char : Model) : number
	local __killed = 0

	if typeof(getconnections) ~= 'function' then
		return 0
	end

	for _, __part in ipairs(__char:GetDescendants()) do
		if not __part:IsA('BasePart') then
			continue
		end

		local __ok, __conns = pcall(getconnections, __part.Changed)

		if not __ok or type(__conns) ~= 'table' then
			continue
		end

		for _, __c in ipairs(__conns) do
			pcall(function()
				if typeof(__c.Disable) == 'function' then
					__c:Disable()
					__killed += 1
				elseif typeof(__c.Disconnect) == 'function' then
					__c:Disconnect()
					__killed += 1
				end
			end)
		end
	end

	return __killed
end

local function __hook_kick() : ()
	if typeof(hookfunction) ~= 'function' then
		return
	end

	pcall(function()
		local __mt = LocalPlayer.Kick

		hookfunction(__mt, function(...)

			return nil
		end)
	end)
end

function AcBypass:init() : AcBypass
	self.__enabled = true
	self.__hooked = false

	return self
end

function AcBypass:start() : ()
	if self.__hooked then
		return
	end

	self.__hooked = true
	__hook_kick()

	if typeof(hookmetamethod) == 'function' and typeof(getnamecallmethod) == 'function' then
		local __self = self
		local __old
		local __handler = function(self, ...)
			local __method = getnamecallmethod()
			local __args = { ... }

			if __self.__enabled then
				if __method == 'FireServer' or __method == 'fireServer' then
					if __is_helloworld(self) then
						local __code = __args[1]

						if __code == 2 or __code == 4 then
							return nil
						end
					end
				elseif __method == 'Kick' or __method == 'kick' then
					if self == LocalPlayer or (typeof(self) == 'Instance' and self:IsA('Player')) then
						return nil
					end
				end
			end

			return __old(self, ...)
		end

		if typeof(newcclosure) == 'function' then
			__handler = newcclosure(__handler)
		end

		__old = hookmetamethod(game, '__namecall', __handler)
		self.__old_namecall = __old
	end

	local function __on_char(__char : Model)
		task.defer(function()
			task.wait(0.35)
			__strip_size_ac(__char)

			task.wait(1.25)
			__strip_size_ac(__char)
		end)
	end

	if LocalPlayer.Character then
		__on_char(LocalPlayer.Character)
	end

	self.__char_conn = LocalPlayer.CharacterAdded:Connect(__on_char)

	self.__scan_thread = task.spawn(function()
		while self.__hooked do
			task.wait(4)

			if self.__enabled and LocalPlayer.Character then
				__strip_size_ac(LocalPlayer.Character)
			end
		end
	end)

	print('[Euphoria]: AC bypass online (HelloWorld 2/4 + size conns + Kick)')
end

function AcBypass:stop() : ()
	self.__enabled = false

end

function AcBypass:set_enabled(__state : boolean) : ()

	self.__enabled = true
end

function AcBypass:destroy() : ()
	self:stop()

	if self.__char_conn then
		self.__char_conn:Disconnect()
		self.__char_conn = nil
	end
end


export type Console = {
	__brand: string,
	__prefix: string,
	__delay: number,
	__running: boolean,
	__steps: { { name: string, run: () -> (boolean, string?) } },

	init: (self: Console, index: { brand: string?, delay: number? }?) -> Console,
	__out: (self: Console, text: string, kind: string?) -> (),
	line: (self: Console, text: string) -> (),
	warn_line: (self: Console, text: string) -> (),
	error_line: (self: Console, text: string) -> (),
	blank: (self: Console) -> (),
	header: (self: Console, lines: { string }) -> (),
	status: (self: Console, message: string, state: string?) -> (),
	timestamp_log: (self: Console, text: string) -> (),
	progress: (self: Console, percent: number) -> (),
	spinner: (self: Console, text: string, duration: number?) -> (),
	add_step: (self: Console, name: string, run: () -> (boolean, string?)) -> (),
	run: (self: Console) -> boolean,
}

local Console : Console = {
	__brand = 'Euphoria',
	__prefix = '[Euphoria]',
	__delay = 0.04,
	__running = false,
	__steps = {},
}
Console.__index = Console

local __SPINNER = { '|', '/', '-', '\\' }

local function __pad2(__n : number) : string
	if __n < 10 then
		return '0' .. tostring(__n)
	end

	return tostring(__n)
end

local function __timestamp() : string
	local __t = os.date('*t')

	return __pad2(__t.hour) .. ':' .. __pad2(__t.min) .. ':' .. __pad2(__t.sec)
end

local function __bar(__percent : number, __width : number?) : string
	local __w = __width or 40
	local __p = math.clamp(math.floor(__percent + 0.5), 0, 100)
	local __filled = math.floor((__p / 100) * __w)

	return string.rep('█', __filled) .. string.rep('░', __w - __filled)
end

function Console:init(__index : { brand: string?, delay: number? }?) : Console
	__index = __index or {}

	self.__brand = __index.brand or 'Euphoria'
	self.__prefix = '[' .. self.__brand .. ']'
	self.__delay = __index.delay or 0.04
	self.__running = false
	self.__steps = {}

	return self
end

function Console:__out(__text : string, __kind : string?) : ()
	__kind = __kind or 'print'

	if __kind == 'warn' then
		warn(__text)
	elseif __kind == 'error' then
		warn('[ERR] ' .. __text)
	else
		print(__text)
	end
end

function Console:line(__text : string) : ()
	self:__out(__text, 'print')
	task.wait(self.__delay)
end

function Console:warn_line(__text : string) : ()
	self:__out(__text, 'warn')
	task.wait(self.__delay)
end

function Console:error_line(__text : string) : ()
	self:__out(__text, 'error')
	task.wait(self.__delay)
end

function Console:blank() : ()
	self:__out('')
	task.wait(self.__delay * 0.5)
end

function Console:header(__lines : { string }) : ()
	for _, __line in ipairs(__lines) do
		if __line == '' then
			self:blank()
		else
			task.wait(self.__delay * 2.2)
			self:__out(__line, 'print')
		end
	end

	self:blank()
end

function Console:status(__message : string, __state : string?) : ()
	local __text = self.__prefix .. ': ' .. __message

	if __state then
		__text ..= ' [' .. __state .. ']'
	end

	self:__out(__text, 'print')
	task.wait(self.__delay * 2)
end

function Console:timestamp_log(__text : string) : ()
	self:__out(__timestamp() .. ' -- ' .. __text, 'print')
	task.wait(self.__delay)
end

function Console:progress(__percent : number) : ()
	local __p = math.clamp(math.floor(__percent + 0.5), 0, 100)
	local __text = self.__prefix .. ': [ ' .. __bar(__p) .. ' ] % ' .. tostring(__p)

	self:__out(__text, 'print')
end

function Console:spinner(__text : string, __duration : number?) : ()
	local __d = __duration or 0.75
	local __t0 = os.clock()
	local __i = 1

	while os.clock() - __t0 < __d do
		self:__out(self.__prefix .. ': ' .. __text .. ' ' .. __SPINNER[__i], 'print')
		__i = (__i % #__SPINNER) + 1
		task.wait(0.08)
	end
end

function Console:add_step(__name : string, __run : () -> (boolean, string?)) : ()
	table.insert(self.__steps, {
		name = __name,
		run = __run,
	})
end

local function __default_steps() : { { name: string, run: () -> (boolean, string?) } }
	local Players = game:GetService('Players')
	local RunService = game:GetService('RunService')

	return {
		{
			name = 'Game loaded',
			run = function()
				if not game:IsLoaded() then
					game.Loaded:Wait()
				end

				return true, 'place is ready'
			end,
		},
		{
			name = 'DataModel services',
			run = function()
				local __need = { 'Players', 'UserInputService', 'TweenService', 'RunService', 'CoreGui', 'Lighting' }

				for _, __name in ipairs(__need) do
					local __ok, __svc = pcall(function()
						return game:GetService(__name)
					end)

					if not __ok or not __svc then
						return false, 'missing ' .. __name
					end
				end

				return true, 'all services ok'
			end,
		},
		{
			name = 'LocalPlayer',
			run = function()
				local __lp = Players.LocalPlayer

				if not __lp then
					Players:GetPropertyChangedSignal('LocalPlayer'):Wait()
					__lp = Players.LocalPlayer
				end

				if not __lp then
					return false, 'LocalPlayer nil'
				end

				return true, __lp.Name .. ' (' .. tostring(__lp.UserId) .. ')'
			end,
		},
		{
			name = 'PlayerGui',
			run = function()
				local __lp = Players.LocalPlayer

				if not __lp then
					return false, 'no player'
				end

				local __pg = __lp:FindFirstChildOfClass('PlayerGui') or __lp:WaitForChild('PlayerGui', 8)

				if not __pg then
					return false, 'PlayerGui timeout'
				end

				return true, 'PlayerGui ready'
			end,
		},
		{
			name = 'Character / workspace',
			run = function()
				local __lp = Players.LocalPlayer

				if not __lp then
					return false, 'no player'
				end

				local __char = __lp.Character or __lp.CharacterAdded:Wait()

				if not __char then
					return false, 'no character'
				end

				local __root = __char:FindFirstChild('HumanoidRootPart') or __char:WaitForChild('HumanoidRootPart', 5)
				local __hum = __char:FindFirstChildOfClass('Humanoid')

				if not __root or not __hum then
					return false, 'rig incomplete'
				end

				if not workspace or not workspace.CurrentCamera then
					return false, 'camera missing'
				end

				return true, 'character + camera ok'
			end,
		},
		{
			name = 'Executor env',
			run = function()
				local __bits = {}

				if typeof(cloneref) == 'function' then
					table.insert(__bits, 'cloneref')
				end

				if typeof(getgenv) == 'function' then
					table.insert(__bits, 'getgenv')
				end

				if typeof(gethui) == 'function' then
					table.insert(__bits, 'gethui')
				end

				if typeof(hookmetamethod) == 'function' then
					table.insert(__bits, 'hmm')
				end

				if #__bits == 0 then
					return true, 'vanilla / limited env'
				end

				return true, table.concat(__bits, ', ')
			end,
		},
		{
			name = 'Heartbeat / render',
			run = function()
				local __ok = false
				local __conn

				__conn = RunService.Heartbeat:Connect(function()
					__ok = true
				end)

				local __t0 = os.clock()

				while not __ok and os.clock() - __t0 < 2 do
					task.wait()
				end

				if __conn then
					__conn:Disconnect()
				end

				if not __ok then
					return false, 'no heartbeat'
				end

				return true, 'render loop alive'
			end,
		},
		{
			name = 'CoreGui access',
			run = function()
				local __ok, __cg = pcall(function()
					return game:GetService('CoreGui')
				end)

				if not __ok or not __cg then
					return false, 'CoreGui blocked'
				end

				local __probe = Instance.new('Folder')
				__probe.Name = '__euphoria_probe'

				local __parent_ok, __err = pcall(function()
					__probe.Parent = __cg
				end)

				if __probe.Parent then
					__probe:Destroy()
				else
					__probe:Destroy()
				end

				if not __parent_ok then
					return false, 'cant parent CoreGui: ' .. tostring(__err)
				end

				return true, 'CoreGui writable'
			end,
		},
	}
end

function Console:run() : boolean
	if self.__running then
		return false
	end

	self.__running = true

	local __brand = self.__brand

	self:blank()
	self:header({
		'Welcome to ' .. __brand .. '!',
		'Main Developers: riq & enrithy',
		'Contributors: community',
		'',
		'Join Us: discord.gg/euphoria',
	})

	self:spinner('Booting', 0.55)
	self:status('Checking Script STATUS:', 'WORKING')
	self:blank()

	local __steps = self.__steps

	if #__steps == 0 then
		__steps = __default_steps()
	end

	local __total = #__steps
	local __passed = 0
	local __failed = 0

	for __i, __step in ipairs(__steps) do
		self:status('Running → ' .. __step.name, '...')

		local __success = false
		local __msg = 'ok'

		local __call_ok, __a, __b = pcall(function()
			return __step.run()
		end)

		if not __call_ok then
			__success = false
			__msg = tostring(__a)
		else
			__success = __a == true
			__msg = __b or (__success and 'ok' or 'failed')
		end

		if __success then
			__passed += 1
			self:status(__step.name, 'OK')
			self:timestamp_log(tostring(__msg))
		else
			__failed += 1
			self:status(__step.name, 'FAIL')
			self:warn_line(self.__prefix .. ': ' .. tostring(__msg))
		end

		self:progress((__i / __total) * 100)
		task.wait(self.__delay * 1.4)
	end

	self:blank()

	if __failed > 0 then
		self:status('Load finished with issues', 'WARN')
		self:warn_line(self.__prefix .. ': ' .. tostring(__passed) .. '/' .. tostring(__total) .. ' steps ok, ' .. tostring(__failed) .. ' failed')
	else
		self:status('Load finished', 'READY')
		self:timestamp_log('all systems green')
	end

	self:progress(100)
	self:blank()
	self:timestamp_log(__brand .. ' console online — open F9 to see this')

	self.__running = false

	return __failed == 0
end


export type ReachConfig = {
	enabled: boolean,
	studs: number,
	head: boolean,
	legs: boolean,
	arms: boolean,
	torso: boolean,
	hrp: boolean,
	visual: boolean,
	smooth: number,
}

export type Reach = {
	__config: ReachConfig,
	__running: boolean,
	__conn: RBXScriptConnection?,
	__char_conn: RBXScriptConnection?,
	__visual: BasePart?,
	__visual_target: number,
	__visual_current: number,
	__last_touch: { [string]: number },
	__parts_cache: { BasePart },
	__balls_cache: { BasePart },
	__ball_refresh: number,
	__part_refresh: number,

	init: (self: Reach) -> Reach,
	set_studs: (self: Reach, value: number) -> (),
	set_enabled: (self: Reach, state: boolean) -> (),
	set_part: (self: Reach, name: string, state: boolean) -> (),
	set_visual: (self: Reach, state: boolean) -> (),
	start: (self: Reach) -> (),
	stop: (self: Reach) -> (),
	destroy: (self: Reach) -> (),
	attach_ui: (self: Reach, library: any) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local RunService = Service.RunService
local CoreGui = Service.CoreGui
local TweenService = Service.TweenService

local LocalPlayer = Players.LocalPlayer

local __BALL_NAMES = {
	TPS = true,
	PSoccerBall = true,
	Bomb = true,
}

local __MAX_STUDS = 10
local __MIN_STUDS = 1

local Reach : Reach = {
	__config = {
		enabled = false,
		studs = 8,
		head = false,
		legs = true,
		arms = true,
		torso = true,
		hrp = true,
		visual = false,
		smooth = 0.18,
	},
	__running = false,
	__conn = nil,
	__char_conn = nil,
	__visual = nil,
	__visual_target = 8,
	__visual_current = 0,
	__last_touch = {},
	__parts_cache = {},
	__balls_cache = {},
	__ball_refresh = 0,
	__part_refresh = 0,
}
Reach.__index = Reach

local function __clamp_studs(__v : number) : number
	return math.clamp(__v, __MIN_STUDS, __MAX_STUDS)
end

local function __is_ball(__part : Instance) : boolean
	if not __part:IsA('BasePart') then
		return false
	end

	if __BALL_NAMES[__part.Name] then
		return true
	end

	local __lower = string.lower(__part.Name)

	if string.find(__lower, 'soccer', 1, true) or string.find(__lower, 'ball', 1, true) then
		if __part.Name ~= 'Ball' then
			return __BALL_NAMES[__part.Name] or __part.Name == 'TPS' or __part.Name == 'PSoccerBall' or __part.Name == 'Bomb'
		end
	end

	return false
end

local function __collect_parts(__self : Reach, __char : Model) : { BasePart }
	local __out = {}
	local __cfg = __self.__config

	local function __push(__name : string)
		local __p = __char:FindFirstChild(__name)

		if __p and __p:IsA('BasePart') then
			table.insert(__out, __p)
		end
	end

	if __cfg.head then
		local __folder = game.Lighting:FindFirstChild(LocalPlayer.Name)
		local __hs = __folder and __folder:FindFirstChild('HeaderSet')

		if __hs and __hs:IsA('BoolValue') and __hs.Value == true then
			__push('Head')
		end
	end

	if __cfg.torso then
		__push('Torso')
		__push('UpperTorso')
		__push('LowerTorso')
	end

	if __cfg.hrp then
		__push('HumanoidRootPart')
	end

	if __cfg.legs then

		__push('Left Leg')
		__push('Right Leg')

		__push('LeftUpperLeg')
		__push('LeftLowerLeg')
		__push('LeftFoot')
		__push('RightUpperLeg')
		__push('RightLowerLeg')
		__push('RightFoot')
	end

	if __cfg.arms then
		__push('Left Arm')
		__push('Right Arm')
		__push('LeftUpperArm')
		__push('LeftLowerArm')
		__push('LeftHand')
		__push('RightUpperArm')
		__push('RightLowerArm')
		__push('RightHand')
	end

	return __out
end

local function __scan_balls() : { BasePart }
	local __out = {}

	for _, __inst in ipairs(workspace:GetDescendants()) do
		if __inst:IsA('BasePart') and __BALL_NAMES[__inst.Name] then
			table.insert(__out, __inst)
		end
	end

	return __out
end

local function __fire_touch(__part : BasePart, __ball : BasePart) : ()
	if typeof(firetouchinterest) ~= 'function' then
		return
	end

	pcall(function()
		firetouchinterest(__part, __ball, 0)
		firetouchinterest(__part, __ball, 1)
	end)
end

local function __ensure_visual(__self : Reach) : ()
	if not __self.__config.visual then
		if __self.__visual then
			__self.__visual:Destroy()
			__self.__visual = nil
		end

		return
	end

	if __self.__visual and __self.__visual.Parent then
		return
	end

	local __char = LocalPlayer.Character
	local __hrp = __char and __char:FindFirstChild('HumanoidRootPart')

	if not __hrp then
		return
	end

	local __ring = Instance.new('Part')
	__ring.Name = '__euphoria_reach_ring'
	__ring.Shape = Enum.PartType.Cylinder
	__ring.Material = Enum.Material.ForceField
	__ring.Color = Color3.fromRGB(255, 255, 255)
	__ring.Transparency = 0.82
	__ring.Anchored = true
	__ring.CanCollide = false
	__ring.CanTouch = false
	__ring.CanQuery = false
	__ring.CastShadow = false
	__ring.Massless = true
	__ring.Size = Vector3.new(0.12, 0.2, 0.2)
	__ring.CFrame = CFrame.new(__hrp.Position) * CFrame.Angles(0, 0, math.rad(90))
	__ring.Parent = workspace.CurrentCamera or workspace

	local __disc = Instance.new('Part')
	__disc.Name = '__euphoria_reach_disc'
	__disc.Shape = Enum.PartType.Cylinder
	__disc.Material = Enum.Material.ForceField
	__disc.Color = Color3.fromRGB(180, 180, 255)
	__disc.Transparency = 0.92
	__disc.Anchored = true
	__disc.CanCollide = false
	__disc.CanTouch = false
	__disc.CanQuery = false
	__disc.CastShadow = false
	__disc.Massless = true
	__disc.Size = Vector3.new(0.05, 0.2, 0.2)
	__disc.Parent = __ring

	__self.__visual = __ring
end

local function __update_visual(__self : Reach, __dt : number) : ()
	if not __self.__config.visual or not __self.__config.enabled then
		if __self.__visual then
			__self.__visual.Transparency = 1
		end

		return
	end

	__ensure_visual(__self)

	local __ring = __self.__visual

	if not __ring then
		return
	end

	local __char = LocalPlayer.Character
	local __hrp = __char and __char:FindFirstChild('HumanoidRootPart') :: BasePart?

	if not __hrp then
		return
	end

	local __smooth = math.clamp(__self.__config.smooth, 0.05, 1)
	__self.__visual_target = __self.__config.studs
	__self.__visual_current += (__self.__visual_target - __self.__visual_current) * math.clamp(__dt / __smooth, 0, 1)

	local __d = __self.__visual_current * 2
	local __pos = __hrp.Position - Vector3.new(0, __hrp.Size.Y * 0.9, 0)

	__ring.Size = Vector3.new(0.12, __d, __d)
	__ring.CFrame = CFrame.new(__pos) * CFrame.Angles(0, 0, math.rad(90))
	__ring.Transparency = 0.78 + math.sin(os.clock() * 2.4) * 0.06

	local __disc = __ring:FindFirstChild('__euphoria_reach_disc')

	if __disc and __disc:IsA('BasePart') then
		__disc.Size = Vector3.new(0.04, __d * 0.92, __d * 0.92)
		__disc.CFrame = __ring.CFrame
		__disc.Transparency = 0.9
	end
end

local function __step(__self : Reach, __dt : number) : ()
	if not __self.__config.enabled then
		__update_visual(__self, __dt)

		return
	end

	local __char = LocalPlayer.Character

	if not __char then
		return
	end

	local __now = os.clock()

	if __now - __self.__part_refresh > 0.5 then
		__self.__parts_cache = __collect_parts(__self, __char)
		__self.__part_refresh = __now
	end

	if __now - __self.__ball_refresh > 0.35 then
		__self.__balls_cache = __scan_balls()
		__self.__ball_refresh = __now
	end

	local __studs = __self.__config.studs
	local __parts = __self.__parts_cache
	local __balls = __self.__balls_cache

	for _, __ball in ipairs(__balls) do
		if not __ball.Parent then
			continue
		end

		if __ball.Locked == false then
			continue
		end

		if __ball.Anchored then
			continue
		end

		local __bp = __ball.Position

		for _, __part in ipairs(__parts) do
			if not __part.Parent then
				continue
			end

			local __dist = (__part.Position - __bp).Magnitude

			local __pad = (__part.Size.Magnitude * 0.15) + (__ball.Size.Magnitude * 0.25)

			if __dist > (__studs + __pad) then
				continue
			end

			local __key = tostring(__part) .. '_' .. tostring(__ball)
			local __last = __self.__last_touch[__key] or 0

			if __now - __last < 0.033 then
				continue
			end

			__self.__last_touch[__key] = __now
			__fire_touch(__part, __ball)
		end
	end

	__update_visual(__self, __dt)
end

function Reach:init() : Reach
	self.__config.enabled = false
	self.__config.head = false
	self.__config.studs = __clamp_studs(self.__config.studs)
	self.__visual_target = self.__config.studs
	self.__visual_current = self.__config.studs
	self.__last_touch = {}
	self.__parts_cache = {}
	self.__balls_cache = {}

	return self
end

function Reach:set_studs(__value : number) : ()
	self.__config.studs = __clamp_studs(__value)
	self.__visual_target = self.__config.studs
end

function Reach:set_enabled(__state : boolean) : ()
	self.__config.enabled = __state and true or false

	if not self.__config.enabled and self.__visual then
		self.__visual.Transparency = 1
	end
end

function Reach:set_part(__name : string, __state : boolean) : ()
	local __key = string.lower(__name)

	if __key == 'head' then
		self.__config.head = __state
	elseif __key == 'legs' then
		self.__config.legs = __state
	elseif __key == 'arms' then
		self.__config.arms = __state
	elseif __key == 'torso' then
		self.__config.torso = __state
	elseif __key == 'hrp' or __key == 'root' then
		self.__config.hrp = __state
	end

	self.__part_refresh = 0
end

function Reach:set_visual(__state : boolean) : ()
	self.__config.visual = __state and true or false

	if not self.__config.visual and self.__visual then
		self.__visual:Destroy()
		self.__visual = nil
	end
end

function Reach:start() : ()
	if self.__running then
		return
	end

	self.__running = true
	self.__part_refresh = 0
	self.__ball_refresh = 0

	self.__conn = RunService.Heartbeat:Connect(function(__dt)
		local __ok, __err = pcall(__step, self, __dt)

		if not __ok then
			warn('[euphoria reach] ' .. tostring(__err))
		end
	end)

	self.__char_conn = LocalPlayer.CharacterAdded:Connect(function()
		self.__part_refresh = 0
		self.__last_touch = {}

		if self.__visual then
			self.__visual:Destroy()
			self.__visual = nil
		end
	end)

end

function Reach:stop() : ()
	self.__running = false

	if self.__conn then
		self.__conn:Disconnect()
		self.__conn = nil
	end

	if self.__char_conn then
		self.__char_conn:Disconnect()
		self.__char_conn = nil
	end

	if self.__visual then
		self.__visual:Destroy()
		self.__visual = nil
	end
end

function Reach:destroy() : ()
	self:stop()
end

function Reach:attach_ui(__library : any) : ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		warn('[euphoria reach] library has no create_tab — run Library:init first')

		return
	end

	local __self = self
	local __tab = __library:create_tab('Reach', 'rbxassetid://10709791437')

	__tab:create_divider('TPS · Street Soccer')

	__tab:create_module({
		title = 'Reach',
		default = false,
		callback = function(__state)
			__self:set_enabled(__state)
		end,
	})

	__tab:create_slider({
		title = 'Studs',
		minimum = __MIN_STUDS,
		maximum = __MAX_STUDS,
		default = __self.__config.studs,
		rounding = 1,
		callback = function(__v)
			__self:set_studs(__v)
		end,
	})
end


export type BallReach = {
	__enabled: boolean,
	__x: number,
	__z: number,
	__y: number,
	__running: boolean,
	__conn: RBXScriptConnection?,
	__char_conn: RBXScriptConnection?,
	__parts: { BasePart },
	__balls: { BasePart },
	__part_t: number,
	__ball_t: number,
	__last_touch: { [string]: number },
	__library: any,

	init: (self: BallReach) -> BallReach,
	set_enabled: (self: BallReach, state: boolean) -> (),
	set_x: (self: BallReach, value: number) -> (),
	set_z: (self: BallReach, value: number) -> (),
	set_y: (self: BallReach, value: number) -> (),
	start: (self: BallReach) -> (),
	stop: (self: BallReach) -> (),
	attach_ui: (self: BallReach, library: any) -> (),
	destroy: (self: BallReach) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local RunService = Service.RunService
local LocalPlayer = Players.LocalPlayer

local __BALL = {
	TPS = true,
	PSoccerBall = true,
	Bomb = true,
}

local __MIN = 1
local __MAX = 10
local __DEFAULT_X = 6
local __DEFAULT_Z = 6
local __DEFAULT_Y = 4

local BallReach: BallReach = {
	__enabled = false,
	__x = __DEFAULT_X,
	__z = __DEFAULT_Z,
	__y = __DEFAULT_Y,
	__running = false,
	__conn = nil,
	__char_conn = nil,
	__parts = {},
	__balls = {},
	__part_t = 0,
	__ball_t = 0,
	__last_touch = {},
	__library = nil,
}
BallReach.__index = BallReach

local function __notify(__self: BallReach, __msg: string, __kind: string?): ()
	local __lib = __self.__library

	if type(__lib) == 'table' and type(__lib.notify) == 'function' then
		pcall(function()
			__lib:notify({
				title = 'BallReach',
				content = __msg,
				duration = 2.2,
				notify_type = __kind or 'normal',
			})
		end)
	end
end

local function __clamp(__v: number): number
	return math.clamp(__v, __MIN, __MAX)
end

local function __is_ball(__inst: Instance): boolean
	return __inst:IsA('BasePart') and __BALL[__inst.Name] == true
end

local function __collect_parts(): { BasePart }
	local __char = LocalPlayer.Character
	local __out = {}

	if not __char then
		return __out
	end

	local __names = {
		'HumanoidRootPart',
		'Torso',
		'UpperTorso',
		'LowerTorso',
		'Left Leg',
		'Right Leg',
		'LeftUpperLeg',
		'LeftLowerLeg',
		'LeftFoot',
		'RightUpperLeg',
		'RightLowerLeg',
		'RightFoot',
		'Left Arm',
		'Right Arm',
		'LeftUpperArm',
		'LeftLowerArm',
		'LeftHand',
		'RightUpperArm',
		'RightLowerArm',
		'RightHand',
		'Head',
	}

	for _, __n in ipairs(__names) do
		local __p = __char:FindFirstChild(__n)

		if __p and __p:IsA('BasePart') then
			table.insert(__out, __p)
		end
	end

	return __out
end

local function __scan_balls(): { BasePart }
	local __out = {}

	for _, __inst in ipairs(workspace:GetDescendants()) do
		if __is_ball(__inst) then
			local __b = __inst :: BasePart

			if not __b.Anchored and __b.Locked ~= false then
				table.insert(__out, __b)
			end
		end
	end

	return __out
end

local function __fire(__part: BasePart, __ball: BasePart): ()
	if typeof(firetouchinterest) ~= 'function' then
		return
	end

	pcall(function()
		firetouchinterest(__part, __ball, 0)
		firetouchinterest(__part, __ball, 1)
	end)
end

-- box reach around the BALL (not size change):
-- |dx| <= X, |dz| <= Z, |dy| <= Y  → touch
local function __in_box(__part: BasePart, __ball: BasePart, __x: number, __y: number, __z: number): boolean
	local __d = __part.Position - __ball.Position
	local __pad = (__part.Size.Magnitude * 0.08) + (__ball.Size.Magnitude * 0.12)

	return math.abs(__d.X) <= (__x + __pad)
		and math.abs(__d.Y) <= (__y + __pad)
		and math.abs(__d.Z) <= (__z + __pad)
end

local function __step(__self: BallReach): ()
	if not __self.__enabled then
		return
	end

	local __now = os.clock()

	if __now - __self.__part_t > 0.45 then
		__self.__parts = __collect_parts()
		__self.__part_t = __now
	end

	if __now - __self.__ball_t > 0.35 then
		__self.__balls = __scan_balls()
		__self.__ball_t = __now
	end

	local __parts = __self.__parts
	local __balls = __self.__balls
	local __x = __self.__x
	local __y = __self.__y
	local __z = __self.__z

	if #__parts == 0 or #__balls == 0 then
		return
	end

	for _, __ball in ipairs(__balls) do
		if not __ball.Parent then
			continue
		end

		for _, __part in ipairs(__parts) do
			if not __part.Parent then
				continue
			end

			if not __in_box(__part, __ball, __x, __y, __z) then
				continue
			end

			local __key = tostring(__part) .. '_' .. tostring(__ball)
			local __last = __self.__last_touch[__key] or 0

			if __now - __last < 0.03 then
				continue
			end

			__self.__last_touch[__key] = __now
			__fire(__part, __ball)
		end
	end
end

function BallReach:init(): BallReach
	self.__enabled = false
	self.__x = __DEFAULT_X
	self.__z = __DEFAULT_Z
	self.__y = __DEFAULT_Y
	self.__parts = {}
	self.__balls = {}
	self.__part_t = 0
	self.__ball_t = 0
	self.__last_touch = {}
	self.__library = nil

	return self
end

function BallReach:set_enabled(__state: boolean): ()
	self.__enabled = __state and true or false
	self.__part_t = 0
	self.__ball_t = 0
	self.__last_touch = {}
end

function BallReach:set_x(__value: number): ()
	self.__x = __clamp(__value)
end

function BallReach:set_z(__value: number): ()
	self.__z = __clamp(__value)
end

function BallReach:set_y(__value: number): ()
	self.__y = __clamp(__value)
end

function BallReach:start(): ()
	if self.__running then
		return
	end

	self.__running = true
	self.__part_t = 0
	self.__ball_t = 0

	self.__conn = RunService.Heartbeat:Connect(function()
		local __ok, __err = pcall(__step, self)

		if not __ok then
			warn('[euphoria ball_reach] ' .. tostring(__err))
		end
	end)

	self.__char_conn = LocalPlayer.CharacterAdded:Connect(function()
		self.__part_t = 0
		self.__last_touch = {}
	end)
end

function BallReach:stop(): ()
	self.__enabled = false
	self.__running = false

	if self.__conn then
		self.__conn:Disconnect()
		self.__conn = nil
	end

	if self.__char_conn then
		self.__char_conn:Disconnect()
		self.__char_conn = nil
	end

	table.clear(self.__parts)
	table.clear(self.__balls)
	table.clear(self.__last_touch)
end

function BallReach:attach_ui(__library: any): ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	self.__library = __library

	local __self = self
	local __tab = __library:create_tab('BallReach', 'rbxassetid://10723345742')

	__tab:create_divider('Reach from the ball (box)')

	__tab:create_module({
		title = 'Ball Reach',
		default = false,
		callback = function(__state)
			__self:set_enabled(__state)
			__notify(
				__self,
				if __state
					then 'on · X ' .. tostring(__self.__x) .. ' Z ' .. tostring(__self.__z) .. ' Y ' .. tostring(__self.__y)
					else 'off'
			)
		end,
	})

	__tab:create_slider({
		title = 'Reach X (sides)',
		minimum = __MIN,
		maximum = __MAX,
		default = __DEFAULT_X,
		rounding = 1,
		callback = function(__v)
			__self:set_x(__v)
		end,
	})

	__tab:create_slider({
		title = 'Reach Z (front/back)',
		minimum = __MIN,
		maximum = __MAX,
		default = __DEFAULT_Z,
		rounding = 1,
		callback = function(__v)
			__self:set_z(__v)
		end,
	})

	__tab:create_slider({
		title = 'Reach Y (up/down)',
		minimum = __MIN,
		maximum = __MAX,
		default = __DEFAULT_Y,
		rounding = 1,
		callback = function(__v)
			__self:set_y(__v)
		end,
	})

	__tab:create_button({
		title = 'Sync X = Z',
		callback = function()
			local __v = __clamp(math.floor(((__self.__x + __self.__z) * 0.5) + 0.5))
			__self:set_x(__v)
			__self:set_z(__v)
			__notify(__self, 'X=Z · ' .. tostring(__v))
		end,
	})

	__tab:create_divider('How it works')
	__tab:create_button({
		title = 'Same as Reach · box around ball · no size',
		callback = function()
			__notify(__self, 'firetouch when limbs inside ball box', 'normal')
		end,
	})
end

function BallReach:destroy(): ()
	self:stop()
	self.__library = nil
end


export type Gk = {
	__reach_on: boolean,
	__stop_on: boolean,
	__x: number,
	__y: number,
	__z: number,
	__stop_range: number,
	__stop_hold: number,
	__hands_only_stop: boolean,
	__use_anchor: boolean,
	__running: boolean,
	__conn: RBXScriptConnection?,
	__step_conn: RBXScriptConnection?,
	__char_conn: RBXScriptConnection?,
	__touch_conns: { RBXScriptConnection },
	__parts_reach: { BasePart },
	__parts_stop: { BasePart },
	__balls: { BasePart },
	__part_t: number,
	__ball_t: number,
	__last_touch: { [string]: number },
	__freeze_until: { [BasePart]: number },
	__freeze_pos: { [BasePart]: Vector3 },
	__library: any,

	init: (self: Gk) -> Gk,
	set_reach: (self: Gk, state: boolean) -> (),
	set_stop: (self: Gk, state: boolean) -> (),
	set_x: (self: Gk, value: number) -> (),
	set_y: (self: Gk, value: number) -> (),
	set_z: (self: Gk, value: number) -> (),
	set_stop_range: (self: Gk, value: number) -> (),
	set_stop_hold: (self: Gk, value: number) -> (),
	start: (self: Gk) -> (),
	stop: (self: Gk) -> (),
	attach_ui: (self: Gk, library: any) -> (),
	destroy: (self: Gk) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local RunService = Service.RunService
local LocalPlayer = Players.LocalPlayer

local __BALL = {
	TPS = true,
	PSoccerBall = true,
	Bomb = true,
}

local __REACH_NAMES = {
	'LeftHand',
	'RightHand',
	'Left Arm',
	'Right Arm',
	'LeftLowerArm',
	'RightLowerArm',
	'LeftUpperArm',
	'RightUpperArm',
	'Torso',
	'UpperTorso',
	'LowerTorso',
	'HumanoidRootPart',
	'Head',
}

local __HAND_NAMES = {
	LeftHand = true,
	RightHand = true,
	['Left Arm'] = true,
	['Right Arm'] = true,
	LeftLowerArm = true,
	RightLowerArm = true,
	LeftUpperArm = true,
	RightUpperArm = true,
}

local __MIN = 1
local __MAX_REACH = 8
local __MAX_STOP = 6
local __DEFAULT_X = 4
local __DEFAULT_Y = 4
local __DEFAULT_Z = 4
local __DEFAULT_STOP = 3.2
local __DEFAULT_HOLD = 0.35

local Gk: Gk = {
	__reach_on = false,
	__stop_on = false,
	__x = __DEFAULT_X,
	__y = __DEFAULT_Y,
	__z = __DEFAULT_Z,
	__stop_range = __DEFAULT_STOP,
	__stop_hold = __DEFAULT_HOLD,
	__hands_only_stop = false, -- whole GK body catches better on hard shots
	__use_anchor = true, -- brief lock so hard shots die
	__running = false,
	__conn = nil,
	__step_conn = nil,
	__char_conn = nil,
	__touch_conns = {},
	__parts_reach = {},
	__parts_stop = {},
	__balls = {},
	__part_t = 0,
	__ball_t = 0,
	__last_touch = {},
	__freeze_until = {},
	__freeze_pos = {},
	__library = nil,
}
Gk.__index = Gk

local function __notify(__self: Gk, __msg: string, __kind: string?): ()
	local __lib = __self.__library

	if type(__lib) == 'table' and type(__lib.notify) == 'function' then
		pcall(function()
			__lib:notify({
				title = 'GK',
				content = __msg,
				duration = 2.2,
				notify_type = __kind or 'normal',
			})
		end)
	end
end

local function __clamp(__v: number, __a: number, __b: number): number
	return math.clamp(__v, __a, __b)
end

local function __is_ball(__inst: Instance): boolean
	return __inst:IsA('BasePart') and __BALL[__inst.Name] == true
end

local function __ball_speed(__ball: BasePart): number
	local __ok, __v = pcall(function()
		return __ball.AssemblyLinearVelocity.Magnitude
	end)

	if __ok and type(__v) == 'number' then
		return __v
	end

	local __ok2, __v2 = pcall(function()
		return (__ball :: any).Velocity.Magnitude
	end)

	if __ok2 and type(__v2) == 'number' then
		return __v2
	end

	return 0
end

local function __collect_parts(__hands_only: boolean): ({ BasePart }, { BasePart })
	local __char = LocalPlayer.Character
	local __reach = {}
	local __stop = {}

	if not __char then
		return __reach, __stop
	end

	for _, __n in ipairs(__REACH_NAMES) do
		local __p = __char:FindFirstChild(__n)

		if __p and __p:IsA('BasePart') then
			table.insert(__reach, __p)

			if (not __hands_only) or __HAND_NAMES[__n] then
				table.insert(__stop, __p)
			end
		end
	end

	if #__stop == 0 then
		__stop = table.clone(__reach)
	end

	return __reach, __stop
end

local function __scan_balls(): { BasePart }
	local __out = {}

	for _, __inst in ipairs(workspace:GetDescendants()) do
		if __is_ball(__inst) then
			table.insert(__out, __inst :: BasePart)
		end
	end

	return __out
end

local function __fire(__part: BasePart, __ball: BasePart): ()
	if typeof(firetouchinterest) ~= 'function' then
		return
	end

	pcall(function()
		firetouchinterest(__part, __ball, 0)
		firetouchinterest(__part, __ball, 1)
	end)
end

local function __in_box(__part: BasePart, __ball: BasePart, __x: number, __y: number, __z: number): boolean
	local __d = __ball.Position - __part.Position
	local __pad = (__part.Size.Magnitude * 0.1) + (__ball.Size.Magnitude * 0.15)

	return math.abs(__d.X) <= (__x + __pad)
		and math.abs(__d.Y) <= (__y + __pad)
		and math.abs(__d.Z) <= (__z + __pad)
end

local function __dist(__a: BasePart, __b: BasePart): number
	return (__a.Position - __b.Position).Magnitude
end

local function __grab_owner(__ball: BasePart): ()
	pcall(function()
		__ball:SetNetworkOwner(LocalPlayer)
	end)

	pcall(function()
		sethiddenproperty(__ball, 'NetworkIsSleeping', false)
	end)
end

local function __ensure_killers(__ball: BasePart): (LinearVelocity?, AngularVelocity?)
	local __att = __ball:FindFirstChild('__euph_gk_att')

	if not __att or not __att:IsA('Attachment') then
		if __att then
			__att:Destroy()
		end

		__att = Instance.new('Attachment')
		__att.Name = '__euph_gk_att'
		__att.Parent = __ball
	end

	local __lv = __ball:FindFirstChild('__euph_gk_lv')

	if not __lv or not __lv:IsA('LinearVelocity') then
		if __lv then
			__lv:Destroy()
		end

		__lv = Instance.new('LinearVelocity')
		__lv.Name = '__euph_gk_lv'
		__lv.Attachment0 = __att
		__lv.RelativeTo = Enum.ActuatorRelativeTo.World
		__lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		__lv.MaxAxesForce = Vector3.new(1e9, 1e9, 1e9)
		__lv.VectorVelocity = Vector3.zero
		__lv.Parent = __ball
	end

	local __av = __ball:FindFirstChild('__euph_gk_av')

	if not __av or not __av:IsA('AngularVelocity') then
		if __av then
			__av:Destroy()
		end

		__av = Instance.new('AngularVelocity')
		__av.Name = '__euph_gk_av'
		__av.Attachment0 = __att
		__av.RelativeTo = Enum.ActuatorRelativeTo.World
		__av.MaxTorque = 1e9
		__av.AngularVelocity = Vector3.zero
		__av.Parent = __ball
	end

	return __lv :: LinearVelocity, __av :: AngularVelocity
end

local function __clear_killers(__ball: BasePart): ()
	for _, __n in ipairs({ '__euph_gk_lv', '__euph_gk_av', '__euph_gk_att' }) do
		local __c = __ball:FindFirstChild(__n)

		if __c then
			pcall(function()
				__c:Destroy()
			end)
		end
	end

	pcall(function()
		__ball.Anchored = false
	end)
end

-- absolute kill for this frame
local function __hard_stop(__self: Gk, __ball: BasePart): ()
	__grab_owner(__ball)

	local __pos = __self.__freeze_pos[__ball] or __ball.Position
	__self.__freeze_pos[__ball] = __pos

	pcall(function()
		__ball.AssemblyLinearVelocity = Vector3.zero
		__ball.AssemblyAngularVelocity = Vector3.zero
	end)

	pcall(function()
		(__ball :: any).Velocity = Vector3.zero
		(__ball :: any).RotVelocity = Vector3.zero
	end)

	local __lv, __av = __ensure_killers(__ball)

	if __lv then
		__lv.Enabled = true
		__lv.VectorVelocity = Vector3.zero
		pcall(function()
			__lv.MaxAxesForce = Vector3.new(1e9, 1e9, 1e9)
		end)
		pcall(function()
			(__lv :: any).MaxForce = 1e9
		end)
	end

	if __av then
		__av.Enabled = true
		__av.AngularVelocity = Vector3.zero
		__av.MaxTorque = 1e9
	end

	-- pin position so strong shots don't slide through
	pcall(function()
		__ball.CFrame = CFrame.new(__pos)
	end)

	if __self.__use_anchor then
		pcall(function()
			__ball.Anchored = true
		end)
	end
end

local function __release(__self: Gk, __ball: BasePart): ()
	__self.__freeze_until[__ball] = nil
	__self.__freeze_pos[__ball] = nil
	__clear_killers(__ball)
end

local function __arm_freeze(__self: Gk, __ball: BasePart, __part: BasePart?): ()
	local __now = os.clock()
	local __speed = __ball_speed(__ball)

	-- hard shot → hold longer (up to ~0.7s)
	local __extra = 0

	if __speed > 40 then
		__extra = 0.15
	end

	if __speed > 70 then
		__extra = 0.28
	end

	if __speed > 100 then
		__extra = 0.4
	end

	local __hold = __clamp(__self.__stop_hold + __extra, 0.12, 0.75)
	local __until = __self.__freeze_until[__ball] or 0

	if __now + __hold > __until then
		__self.__freeze_until[__ball] = __now + __hold
	end

	if not __self.__freeze_pos[__ball] then
		__self.__freeze_pos[__ball] = __ball.Position
	end

	__hard_stop(__self, __ball)

	if __part then
		__fire(__part, __ball)
		__fire(__part, __ball)
	end
end

local function __bind_touched(__self: Gk): ()
	for _, __c in ipairs(__self.__touch_conns) do
		pcall(function()
			__c:Disconnect()
		end)
	end

	table.clear(__self.__touch_conns)

	if not __self.__stop_on then
		return
	end

	for _, __part in ipairs(__self.__parts_stop) do
		local __conn = __part.Touched:Connect(function(__hit)
			if not __self.__stop_on then
				return
			end

			if not __is_ball(__hit) then
				return
			end

			local __ok, __err = pcall(function()
				__arm_freeze(__self, __hit :: BasePart, __part)
			end)

			if not __ok then
				warn('[euphoria gk touch] ' .. tostring(__err))
			end
		end)

		table.insert(__self.__touch_conns, __conn)
	end
end

local function __step(__self: Gk): ()
	if not __self.__reach_on and not __self.__stop_on then
		return
	end

	local __now = os.clock()

	if __now - __self.__part_t > 0.35 then
		local __r, __s = __collect_parts(__self.__hands_only_stop)
		local __need_rebind = #__s ~= #__self.__parts_stop

		__self.__parts_reach = __r
		__self.__parts_stop = __s
		__self.__part_t = __now

		if __need_rebind or #__self.__touch_conns == 0 then
			__bind_touched(__self)
		end
	end

	if __now - __self.__ball_t > 0.25 then
		__self.__balls = __scan_balls()
		__self.__ball_t = __now
	end

	local __balls = __self.__balls

	-- maintain freezes every frame (this is what kills hard shots)
	if __self.__stop_on then
		for __ball, __until in pairs(__self.__freeze_until) do
			if typeof(__ball) ~= 'Instance' or not __ball.Parent then
				__self.__freeze_until[__ball] = nil
				__self.__freeze_pos[__ball] = nil
				continue
			end

			if __now <= __until then
				__hard_stop(__self, __ball)
			else
				__release(__self, __ball)
			end
		end
	end

	-- GK reach box
	if __self.__reach_on then
		local __parts = __self.__parts_reach
		local __x, __y, __z = __self.__x, __self.__y, __self.__z

		for _, __ball in ipairs(__balls) do
			if not __ball.Parent then
				continue
			end

			for _, __part in ipairs(__parts) do
				if not __part.Parent then
					continue
				end

				if not __in_box(__part, __ball, __x, __y, __z) then
					continue
				end

				local __key = 'r:' .. tostring(__part) .. ':' .. tostring(__ball)
				local __last = __self.__last_touch[__key] or 0

				if __now - __last < 0.025 then
					continue
				end

				__self.__last_touch[__key] = __now
				__fire(__part, __ball)
			end
		end
	end

	-- proximity catch (backup if Touched misses fast balls)
	if __self.__stop_on then
		local __parts = __self.__parts_stop
		local __range = __self.__stop_range

		for _, __ball in ipairs(__balls) do
			if not __ball.Parent or __ball.Anchored and not __self.__freeze_until[__ball] then
				-- skip permanently anchored map props; allow our own freeze anchors
				if not __self.__freeze_until[__ball] then
					continue
				end
			end

			for _, __part in ipairs(__parts) do
				if not __part.Parent then
					continue
				end

				local __pad = (__part.Size.Magnitude * 0.25) + (__ball.Size.Magnitude * 0.4)
				local __d = __dist(__part, __ball)

				-- expand catch window a bit for very fast balls
				local __spd = __ball_speed(__ball)
				local __boost = if __spd > 80 then 0.8 elseif __spd > 50 then 0.45 else 0

				if __d > (__range + __pad + __boost) then
					continue
				end

				__arm_freeze(__self, __ball, __part)
				break
			end
		end
	end
end

function Gk:init(): Gk
	self.__reach_on = false
	self.__stop_on = false
	self.__x = __DEFAULT_X
	self.__y = __DEFAULT_Y
	self.__z = __DEFAULT_Z
	self.__stop_range = __DEFAULT_STOP
	self.__stop_hold = __DEFAULT_HOLD
	self.__hands_only_stop = false
	self.__use_anchor = true
	self.__parts_reach = {}
	self.__parts_stop = {}
	self.__balls = {}
	self.__part_t = 0
	self.__ball_t = 0
	self.__last_touch = {}
	self.__freeze_until = {}
	self.__freeze_pos = {}
	self.__touch_conns = {}
	self.__library = nil

	return self
end

function Gk:set_reach(__state: boolean): ()
	self.__reach_on = __state and true or false
	self.__part_t = 0
	self.__last_touch = {}
end

function Gk:set_stop(__state: boolean): ()
	self.__stop_on = __state and true or false

	if not self.__stop_on then
		for __ball in pairs(self.__freeze_until) do
			if typeof(__ball) == 'Instance' and __ball:IsA('BasePart') then
				__release(self, __ball)
			end
		end

		table.clear(self.__freeze_until)
		table.clear(self.__freeze_pos)
		__bind_touched(self)
	else
		self.__part_t = 0
		__bind_touched(self)
	end
end

function Gk:set_x(__v: number): ()
	self.__x = __clamp(__v, __MIN, __MAX_REACH)
end

function Gk:set_y(__v: number): ()
	self.__y = __clamp(__v, __MIN, __MAX_REACH)
end

function Gk:set_z(__v: number): ()
	self.__z = __clamp(__v, __MIN, __MAX_REACH)
end

function Gk:set_stop_range(__v: number): ()
	self.__stop_range = __clamp(__v, 1, __MAX_STOP)
end

function Gk:set_stop_hold(__v: number): ()
	self.__stop_hold = __clamp(__v, 0.1, 0.75)
end

function Gk:start(): ()
	if self.__running then
		return
	end

	self.__running = true
	self.__part_t = 0
	self.__ball_t = 0

	local function __tick()
		local __ok, __err = pcall(__step, self)

		if not __ok then
			warn('[euphoria gk] ' .. tostring(__err))
		end
	end

	-- Heartbeat + Stepped = freeze sticks on hard shots
	self.__conn = RunService.Heartbeat:Connect(__tick)
	self.__step_conn = RunService.Stepped:Connect(function()
		if not self.__stop_on then
			return
		end

		local __now = os.clock()

		for __ball, __until in pairs(self.__freeze_until) do
			if typeof(__ball) == 'Instance' and __ball.Parent and __now <= __until then
				__hard_stop(self, __ball)
			end
		end
	end)

	self.__char_conn = LocalPlayer.CharacterAdded:Connect(function()
		self.__part_t = 0
		self.__last_touch = {}

		for __ball in pairs(self.__freeze_until) do
			if typeof(__ball) == 'Instance' and __ball:IsA('BasePart') then
				__release(self, __ball)
			end
		end

		table.clear(self.__freeze_until)
		table.clear(self.__freeze_pos)

		task.defer(function()
			__bind_touched(self)
		end)
	end)
end

function Gk:stop(): ()
	self.__reach_on = false
	self.__stop_on = false
	self.__running = false

	for __ball in pairs(self.__freeze_until) do
		if typeof(__ball) == 'Instance' and __ball:IsA('BasePart') then
			__release(self, __ball)
		end
	end

	if self.__conn then
		self.__conn:Disconnect()
		self.__conn = nil
	end

	if self.__step_conn then
		self.__step_conn:Disconnect()
		self.__step_conn = nil
	end

	if self.__char_conn then
		self.__char_conn:Disconnect()
		self.__char_conn = nil
	end

	for _, __c in ipairs(self.__touch_conns) do
		pcall(function()
			__c:Disconnect()
		end)
	end

	table.clear(self.__touch_conns)
	table.clear(self.__parts_reach)
	table.clear(self.__parts_stop)
	table.clear(self.__balls)
	table.clear(self.__last_touch)
	table.clear(self.__freeze_until)
	table.clear(self.__freeze_pos)
end

function Gk:attach_ui(__library: any): ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	self.__library = __library

	local __self = self
	local __tab = __library:create_tab('GK', 'rbxassetid://10723407389')

	__tab:create_divider('GK Reach Box')

	__tab:create_module({
		title = 'GK Reach Box',
		default = false,
		callback = function(__state)
			__self:set_reach(__state)
			__notify(__self, if __state then 'reach box on' else 'reach box off')
		end,
	})

	__tab:create_slider({
		title = 'Box X',
		minimum = __MIN,
		maximum = __MAX_REACH,
		default = __DEFAULT_X,
		rounding = 1,
		callback = function(__v)
			__self:set_x(__v)
		end,
	})

	__tab:create_slider({
		title = 'Box Y',
		minimum = __MIN,
		maximum = __MAX_REACH,
		default = __DEFAULT_Y,
		rounding = 1,
		callback = function(__v)
			__self:set_y(__v)
		end,
	})

	__tab:create_slider({
		title = 'Box Z',
		minimum = __MIN,
		maximum = __MAX_REACH,
		default = __DEFAULT_Z,
		rounding = 1,
		callback = function(__v)
			__self:set_z(__v)
		end,
	})

	__tab:create_divider('Toqué el balón → freno seco')

	__tab:create_module({
		title = 'Freno seco al toque',
		default = false,
		callback = function(__state)
			__self:set_stop(__state)
			__notify(__self, if __state then 'CATCH LOCK on · tiros fuertes mueren' else 'freno off')
		end,
	})

	__tab:create_module({
		title = 'Anchor breve (recomendado)',
		default = true,
		callback = function(__state)
			__self.__use_anchor = __state and true or false
			__notify(__self, if __self.__use_anchor then 'anchor lock on' else 'solo velocity/constraints')
		end,
	})

	__tab:create_module({
		title = 'Solo manos (off = cuerpo entero)',
		default = false,
		callback = function(__state)
			__self.__hands_only_stop = __state and true or false
			__self.__part_t = 0
			__bind_touched(__self)
		end,
	})

	__tab:create_slider({
		title = 'Distancia de toque',
		minimum = 1,
		maximum = __MAX_STOP,
		default = __DEFAULT_STOP,
		rounding = 0.1,
		callback = function(__v)
			__self:set_stop_range(__v)
		end,
	})

	__tab:create_slider({
		title = 'Hold base (x0.01s)',
		minimum = 15,
		maximum = 60,
		default = 35,
		rounding = 1,
		callback = function(__v)
			__self:set_stop_hold(__v / 100)
		end,
	})

	__tab:create_divider('Info')
	__tab:create_button({
		title = 'Tiro fuerte = hold auto más largo',
		callback = function()
			__notify(__self, 'Touched + proximity + Heartbeat/Stepped lock', 'normal')
		end,
	})
end

function Gk:destroy(): ()
	self:stop()
	self.__library = nil
end


export type AutoHeader = {
	__enabled: boolean,
	__range: number,
	__conn: RBXScriptConnection?,
	__last: number,

	init: (self: AutoHeader) -> AutoHeader,
	set_enabled: (self: AutoHeader, state: boolean) -> (),
	set_range: (self: AutoHeader, value: number) -> (),
	start: (self: AutoHeader) -> (),
	stop: (self: AutoHeader) -> (),
	attach_ui: (self: AutoHeader, library: any) -> (),
	destroy: (self: AutoHeader) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local RunService = Service.RunService
local LocalPlayer = Players.LocalPlayer

local __BALL = { TPS = true, PSoccerBall = true, Bomb = true }

local AutoHeader : AutoHeader = {
	__enabled = false,
	__range = 8,
	__conn = nil,
	__last = 0,
}
AutoHeader.__index = AutoHeader

local function __game_header_on() : boolean
	local __folder = game.Lighting:FindFirstChild(LocalPlayer.Name)

	if not __folder then
		return false
	end

	local __hs = __folder:FindFirstChild('HeaderSet')

	if not __hs or not __hs:IsA('BoolValue') then
		return false
	end

	return __hs.Value == true
end

local function __balls() : { BasePart }
	local __out = {}

	for _, __inst in ipairs(workspace:GetDescendants()) do
		if __inst:IsA('BasePart') and __BALL[__inst.Name] and __inst.Locked ~= false and not __inst.Anchored then
			table.insert(__out, __inst)
		end
	end

	return __out
end

local function __fire(__head : BasePart, __ball : BasePart) : ()
	if typeof(firetouchinterest) ~= 'function' then
		return
	end

	pcall(function()
		firetouchinterest(__head, __ball, 0)
		firetouchinterest(__head, __ball, 1)
	end)
end

function AutoHeader:init() : AutoHeader
	self.__enabled = false
	self.__range = 8
	self.__last = 0

	return self
end

function AutoHeader:set_enabled(__state : boolean) : ()
	self.__enabled = __state and true or false
end

function AutoHeader:set_range(__value : number) : ()
	self.__range = math.clamp(__value, 2, 12)
end

function AutoHeader:start() : ()
	if self.__conn then
		return
	end

	self.__conn = RunService.Heartbeat:Connect(function()
		if not self.__enabled then
			return
		end

		if not __game_header_on() then
			return
		end

		local __char = LocalPlayer.Character
		local __head = __char and __char:FindFirstChild('Head') :: BasePart?

		if not __head then
			return
		end

		local __now = os.clock()

		if __now - self.__last < 0.04 then
			return
		end

		local __hp = __head.Position

		for _, __ball in ipairs(__balls()) do
			local __bp = __ball.Position
			local __dist = (__hp - __bp).Magnitude

			if __dist > self.__range then
				continue
			end

			local __rel_y = __bp.Y - __hp.Y

			if __rel_y < -2.2 then
				continue
			end

			self.__last = __now
			__fire(__head, __ball)
		end
	end)
end

function AutoHeader:stop() : ()
	if self.__conn then
		self.__conn:Disconnect()
		self.__conn = nil
	end
end

function AutoHeader:attach_ui(__library : any) : ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	local __self = self
	local __tab = __library:create_tab('Header', 'rbxassetid://10734888000')

	__tab:create_divider('Auto Header')

	__tab:create_module({
		title = 'Auto Header',
		default = false,
		callback = function(__state)
			__self:set_enabled(__state)
		end,
	})

	__tab:create_slider({
		title = 'Range',
		minimum = 2,
		maximum = 12,
		default = __self.__range,
		rounding = 1,
		callback = function(__v)
			__self:set_range(__v)
		end,
	})
end

function AutoHeader:destroy() : ()
	self:stop()
end


export type Reacts = {
	__enabled: boolean,
	__active: boolean,
	__conn: RBXScriptConnection?,
	__input_began: RBXScriptConnection?,
	__input_ended: RBXScriptConnection?,
	__ball_add: RBXScriptConnection?,
	__ball_rem: RBXScriptConnection?,
	__balls: { [BasePart]: boolean },
	__leg: BasePart?,
	__hrp: BasePart?,
	__part_t: number,
	__pulse_i: number,
	__job: thread?,

	init: (self: Reacts) -> Reacts,
	set_enabled: (self: Reacts, state: boolean) -> (),
	start: (self: Reacts) -> (),
	stop: (self: Reacts) -> (),
	attach_ui: (self: Reacts, library: any) -> (),
	destroy: (self: Reacts) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local RunService = Service.RunService
local UserInputService = Service.UserInputService
local LocalPlayer = Players.LocalPlayer

local __BALL = { TPS = true, PSoccerBall = true, Bomb = true }
local __RANGE = 10
local __RANGE_SQ = __RANGE * __RANGE
local __SCAN_SQ = 18 * 18

local Reacts : Reacts = {
	__enabled = false,
	__active = false,
	__conn = nil,
	__input_began = nil,
	__input_ended = nil,
	__ball_add = nil,
	__ball_rem = nil,
	__balls = {},
	__leg = nil,
	__hrp = nil,
	__part_t = 0,
	__pulse_i = 0,
	__job = nil,
}
Reacts.__index = Reacts

local function __is_ball(__inst : Instance) : boolean
	return __inst:IsA('BasePart') and __BALL[__inst.Name] == true
end

local function __scan_balls(__self : Reacts) : ()
	table.clear(__self.__balls)

	for _, __inst in ipairs(workspace:GetDescendants()) do
		if __is_ball(__inst) and not (__inst :: BasePart).Anchored then
			__self.__balls[__inst :: BasePart] = true
		end
	end
end

local function __cache_parts(__self : Reacts, __force : boolean?) : ()
	local __now = os.clock()

	if not __force and __now - __self.__part_t < 0.35 and __self.__leg and __self.__leg.Parent then
		return
	end

	local __char = LocalPlayer.Character

	if not __char then
		__self.__leg = nil
		__self.__hrp = nil

		return
	end

	__self.__hrp = __char:FindFirstChild('HumanoidRootPart') :: BasePart?

	local __pack = LocalPlayer:FindFirstChild('Backpack')
	local __switch = 1

	if __pack then
		local __sv = __pack:FindFirstChild('Switch')

		if __sv and typeof(__sv.Value) == 'number' then
			__switch = __sv.Value
		end
	end

	if __switch == 0 then
		__self.__leg = (__char:FindFirstChild('LeftFoot')
			or __char:FindFirstChild('LeftLowerLeg')
			or __char:FindFirstChild('Left Leg')) :: BasePart?
	else
		__self.__leg = (__char:FindFirstChild('RightFoot')
			or __char:FindFirstChild('RightLowerLeg')
			or __char:FindFirstChild('Right Leg')) :: BasePart?
	end

	__self.__part_t = __now
end

local function __fire(__part : BasePart, __ball : BasePart) : ()
	if typeof(firetouchinterest) ~= 'function' then
		return
	end

	pcall(firetouchinterest, __part, __ball, 0)
	pcall(firetouchinterest, __part, __ball, 1)
end

local function __nearest_ball(__self : Reacts, __root : Vector3) : BasePart?
	local __best : BasePart? = nil
	local __best_d = __SCAN_SQ

	for __ball in pairs(__self.__balls) do
		if not __ball.Parent then
			__self.__balls[__ball] = nil
			continue
		end

		if __ball.Locked == false or __ball.Anchored then
			continue
		end

		local __d = (__ball.Position - __root).Magnitude
		local __d2 = __d * __d

		if __d2 < __best_d then
			__best_d = __d2
			__best = __ball
		end
	end

	return __best
end

local function __hit_once(__self : Reacts) : ()
	if not __self.__enabled or not __self.__active then
		return
	end

	__cache_parts(__self, false)

	local __leg = __self.__leg
	local __hrp = __self.__hrp

	if not __leg or not __leg.Parent then
		return
	end

	local __root = (__hrp and __hrp.Position) or __leg.Position
	local __ball = __nearest_ball(__self, __root)

	if not __ball then
		return
	end

	local __bp = __ball.Position
	local __vel = __ball.AssemblyLinearVelocity
	local __speed = __vel.Magnitude
	local __look = if __speed > 25 then 0.1 elseif __speed > 10 then 0.07 else 0.04
	local __future = __bp + __vel * __look
	local __pp = __leg.Position

	local __dx = __pp.X - __bp.X
	local __dy = __pp.Y - __bp.Y
	local __dz = __pp.Z - __bp.Z
	local __d0 = __dx * __dx + __dy * __dy + __dz * __dz

	local __fx = __pp.X - __future.X
	local __fy = __pp.Y - __future.Y
	local __fz = __pp.Z - __future.Z
	local __d1 = __fx * __fx + __fy * __fy + __fz * __fz

	if __d0 <= __RANGE_SQ or __d1 <= __RANGE_SQ then
		__fire(__leg, __ball)
	end
end

local function __run_window(__self : Reacts, __ticks : number) : ()
	if __self.__job then
		task.cancel(__self.__job)
		__self.__job = nil
	end

	__self.__active = true
	__cache_parts(__self, true)
	__hit_once(__self)

	__self.__job = task.spawn(function()
		for __i = 1, __ticks do
			if not __self.__enabled then
				break
			end

			__hit_once(__self)
			task.wait()
		end

		__self.__active = false
		__self.__job = nil
	end)
end

function Reacts:init() : Reacts
	self.__enabled = false
	self.__active = false
	self.__balls = {}
	self.__leg = nil
	self.__hrp = nil
	self.__part_t = 0
	self.__pulse_i = 0
	self.__job = nil

	return self
end

function Reacts:set_enabled(__state : boolean) : ()
	self.__enabled = __state and true or false

	if self.__enabled then
		__scan_balls(self)
	else
		self.__active = false

		if self.__job then
			task.cancel(self.__job)
			self.__job = nil
		end
	end
end

function Reacts:start() : ()
	if self.__input_began then
		return
	end

	__scan_balls(self)

	self.__ball_add = workspace.DescendantAdded:Connect(function(__inst)
		if __is_ball(__inst) and not (__inst :: BasePart).Anchored then
			self.__balls[__inst :: BasePart] = true
		end
	end)

	self.__ball_rem = workspace.DescendantRemoving:Connect(function(__inst)
		if __inst:IsA('BasePart') then
			self.__balls[__inst] = nil
		end
	end)

	self.__input_began = UserInputService.InputBegan:Connect(function(__input, __gpe)
		if __gpe or not self.__enabled then
			return
		end

		local __k = __input.KeyCode
		local __t = __input.UserInputType

		if __k == Enum.KeyCode.X or __k == Enum.KeyCode.F or __k == Enum.KeyCode.ButtonX then
			__run_window(self, 10)
		elseif __k == Enum.KeyCode.G then
			__run_window(self, 9)
		elseif __t == Enum.UserInputType.MouseButton1 or __k == Enum.KeyCode.ButtonR2 or __k == Enum.KeyCode.ButtonB then
			__hit_once(self)
		end
	end)

	self.__input_ended = UserInputService.InputEnded:Connect(function(__input, __gpe)
		if not self.__enabled then
			return
		end

		local __t = __input.UserInputType
		local __k = __input.KeyCode

		if __t == Enum.UserInputType.MouseButton1 or __k == Enum.KeyCode.ButtonR2 or __k == Enum.KeyCode.ButtonB then
			__run_window(self, 12)
		end
	end)
end

function Reacts:stop() : ()
	self.__active = false

	if self.__job then
		task.cancel(self.__job)
		self.__job = nil
	end

	if self.__conn then
		self.__conn:Disconnect()
		self.__conn = nil
	end

	if self.__input_began then
		self.__input_began:Disconnect()
		self.__input_began = nil
	end

	if self.__input_ended then
		self.__input_ended:Disconnect()
		self.__input_ended = nil
	end

	if self.__ball_add then
		self.__ball_add:Disconnect()
		self.__ball_add = nil
	end

	if self.__ball_rem then
		self.__ball_rem:Disconnect()
		self.__ball_rem = nil
	end

	table.clear(self.__balls)
end

function Reacts:attach_ui(__library : any) : ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	local __self = self
	local __tab = __library:create_tab('Reacts', 'rbxassetid://10709753149')

	__tab:create_divider('Ball reaction')

	__tab:create_module({
		title = 'Reacts',
		default = false,
		callback = function(__state)
			__self:set_enabled(__state)
		end,
	})
end

function Reacts:destroy() : ()
	self:stop()
end


export type PingChanger = {
	__enabled: boolean,
	__ms: number,
	__running: boolean,
	__last: number,
	__conn: RBXScriptConnection?,
	__hooked: boolean,
	__old_gnp: any,
	__library: any,

	init: (self: PingChanger) -> PingChanger,
	set_enabled: (self: PingChanger, state: boolean) -> (),
	set_ms: (self: PingChanger, value: number) -> (),
	start: (self: PingChanger) -> (),
	stop: (self: PingChanger) -> (),
	attach_ui: (self: PingChanger, library: any) -> (),
	destroy: (self: PingChanger) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local RunService = Service.RunService
local LocalPlayer = Players.LocalPlayer

local __MIN_MS = 1
local __MAX_MS = 120
local __DEFAULT_MS = 5

local PingChanger: PingChanger = {
	__enabled = false,
	__ms = __DEFAULT_MS,
	__running = false,
	__last = 0,
	__conn = nil,
	__hooked = false,
	__old_gnp = nil,
	__library = nil,
}
PingChanger.__index = PingChanger

local function __notify(__self: PingChanger, __msg: string, __kind: string?): ()
	local __lib = __self.__library

	if type(__lib) == 'table' and type(__lib.notify) == 'function' then
		pcall(function()
			__lib:notify({
				title = 'Ping',
				content = __msg,
				duration = 2.2,
				notify_type = __kind or 'normal',
			})
		end)
	end
end

local function __clamp_ms(__v: number): number
	return math.clamp(math.floor(__v + 0.5), __MIN_MS, __MAX_MS)
end

local function __find_ping_value(): IntValue?
	local __pack = LocalPlayer:FindFirstChild('Backpack')

	if not __pack then
		return nil
	end

	local __p = __pack:FindFirstChild('Ping')

	if __p and __p:IsA('IntValue') then
		return __p
	end

	return nil
end

local function __write_backpack_ping(__ms: number): ()
	local __ping = __find_ping_value()

	if not __ping then
		return
	end

	if __ping.Value ~= __ms then
		pcall(function()
			__ping.Value = __ms
		end)
	end
end

local function __ensure_hook(__self: PingChanger): ()
	if __self.__hooked then
		return
	end

	if typeof(hookfunction) ~= 'function' then
		return
	end

	local __ok, __err = pcall(function()
		local __method = LocalPlayer.GetNetworkPing

		if typeof(__method) ~= 'function' then
			return
		end

		__self.__old_gnp = hookfunction(__method, function(__player, ...)
			if __self.__enabled and __player == LocalPlayer then
				return __self.__ms / 1000
			end

			if __self.__old_gnp then
				return __self.__old_gnp(__player, ...)
			end

			return 0.05
		end)

		__self.__hooked = true
	end)

	if not __ok then
		warn('[euphoria ping] hook ' .. tostring(__err))
	end
end

local function __apply(__self: PingChanger): ()
	if not __self.__enabled then
		return
	end

	__write_backpack_ping(__self.__ms)
end

function PingChanger:init(): PingChanger
	self.__enabled = false
	self.__ms = __DEFAULT_MS
	self.__last = 0
	self.__library = nil

	return self
end

function PingChanger:set_ms(__value: number): ()
	self.__ms = __clamp_ms(__value)

	if self.__enabled then
		__apply(self)
	end
end

function PingChanger:set_enabled(__state: boolean): ()
	self.__enabled = __state and true or false

	if self.__enabled then
		__ensure_hook(self)
		__apply(self)
	end
end

function PingChanger:start(): ()
	if self.__running then
		return
	end

	self.__running = true
	self.__last = 0
	__ensure_hook(self)

	self.__conn = RunService.Heartbeat:Connect(function()
		if not self.__enabled then
			return
		end

		local __now = os.clock()

		if __now - self.__last < 0.2 then
			return
		end

		self.__last = __now

		local __ok, __err = pcall(__apply, self)

		if not __ok then
			warn('[euphoria ping] ' .. tostring(__err))
		end
	end)
end

function PingChanger:stop(): ()
	self.__enabled = false

	if self.__conn then
		self.__conn:Disconnect()
		self.__conn = nil
	end

	self.__running = false
end

function PingChanger:attach_ui(__library: any): ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	self.__library = __library

	local __self = self
	local __tab = __library:create_tab('Ping', 'rbxassetid://10734950309')

	__tab:create_divider('Client ping display')

	__tab:create_module({
		title = 'Ping Changer',
		default = false,
		callback = function(__state)
			__self:set_enabled(__state)
			__notify(__self, if __state then 'on · ' .. tostring(__self.__ms) .. ' ms' else 'off')
		end,
	})

	__tab:create_slider({
		title = 'Ping (ms)',
		minimum = __MIN_MS,
		maximum = __MAX_MS,
		default = __DEFAULT_MS,
		rounding = 1,
		callback = function(__v)
			__self:set_ms(__v)
		end,
	})

	__tab:create_divider('Presets')

	local function __preset(__ms: number)
		__self:set_ms(__ms)

		if not __self.__enabled then
			__self:set_enabled(true)
		end

		__notify(__self, tostring(__ms) .. ' ms')
	end

	__tab:create_button({
		title = 'Preset · 4 ms',
		callback = function()
			__preset(4)
		end,
	})

	__tab:create_button({
		title = 'Preset · 5 ms',
		callback = function()
			__preset(5)
		end,
	})

	__tab:create_button({
		title = 'Preset · 10 ms',
		callback = function()
			__preset(10)
		end,
	})

	__tab:create_button({
		title = 'Preset · 20 ms',
		callback = function()
			__preset(20)
		end,
	})

	__tab:create_button({
		title = 'Read GetNetworkPing now',
		callback = function()
			local __ms = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5)

			__notify(
				__self,
				(if __self.__enabled then 'spoofed · ' else 'real · ') .. tostring(__ms) .. ' ms',
				if __self.__enabled then 'warn' else 'normal'
			)
		end,
	})

	__tab:create_divider('Note')
	__tab:create_button({
		title = 'Display spoof only · not real latency',
		callback = function()
			__notify(__self, 'Backpack.Ping + GetNetworkPing hook', 'warn')
		end,
	})
end

function PingChanger:destroy(): ()
	self:stop()
	self.__library = nil
end


export type AvatarStealer = {
	__target: string,
	__saved: HumanoidDescription?,
	__busy: boolean,
	__library: any,

	init: (self: AvatarStealer) -> AvatarStealer,
	start: (self: AvatarStealer) -> (),
	stop: (self: AvatarStealer) -> (),
	attach_ui: (self: AvatarStealer, library: any) -> (),
	steal: (self: AvatarStealer, target: string | number | Player) -> (boolean, string),
	restore: (self: AvatarStealer) -> (boolean, string),
	save_self: (self: AvatarStealer) -> (boolean, string),
	destroy: (self: AvatarStealer) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local LocalPlayer = Players.LocalPlayer

local AvatarStealer: AvatarStealer = {
	__target = '',
	__saved = nil,
	__busy = false,
	__library = nil,
}
AvatarStealer.__index = AvatarStealer

local function __notify(__self: AvatarStealer, __content: string, __kind: string?): ()
	local __lib = __self.__library

	if type(__lib) == 'table' and type(__lib.notify) == 'function' then
		__lib:notify({
			title = 'Avatar',
			content = __content,
			duration = 2.5,
			notify_type = __kind or 'normal',
		})
	end
end

local function __trim(__s: any): string
	return (string.gsub(tostring(__s or ''), '^%s+', '')):gsub('%s+$', '')
end

local function __humanoid(__char: Model?): Humanoid?
	if not __char then
		return nil
	end

	local __h = __char:FindFirstChildOfClass('Humanoid')

	if __h and __h:IsA('Humanoid') then
		return __h
	end

	return nil
end

local function __wait_character(__player: Player, __timeout: number?): Model?
	local __t = __timeout or 5
	local __char = __player.Character

	if __char and __humanoid(__char) then
		return __char
	end

	local __deadline = os.clock() + __t

	while os.clock() < __deadline do
		__char = __player.Character

		if __char and __humanoid(__char) then
			return __char
		end

		task.wait(0.05)
	end

	return __player.Character
end

local function __clone_desc(__desc: HumanoidDescription): HumanoidDescription?
	local __ok, __cloned = pcall(function()
		return __desc:Clone()
	end)

	if __ok and __cloned and __cloned:IsA('HumanoidDescription') then
		return __cloned
	end

	return nil
end

local function __asset_uri(__id: number): string
	return 'rbxassetid://' .. tostring(__id)
end

local function __parse_query(__query: string | number | Player): (string?, number?, Player?)
	if typeof(__query) == 'Instance' and (__query :: Instance):IsA('Player') then
		local __p = __query :: Player

		return __p.Name, __p.UserId, __p
	end

	if type(__query) == 'number' then
		local __id = math.floor(__query :: number)

		if __id <= 0 then
			return nil, nil, nil
		end

		for _, __p in ipairs(Players:GetPlayers()) do
			if __p.UserId == __id then
				return __p.Name, __id, __p
			end
		end

		return tostring(__id), __id, nil
	end

	local __raw = __trim(__query)

	if __raw == '' then
		return nil, nil, nil
	end

	if string.sub(__raw, 1, 1) == '@' then
		__raw = __trim(string.sub(__raw, 2))
	end

	local __url_id = string.match(__raw, 'roblox%.com/users/(%d+)') or string.match(__raw, 'users/(%d+)')

	if __url_id then
		return __parse_query(tonumber(__url_id) :: number)
	end

	local __as_num = tonumber(__raw)

	if __as_num and __as_num == math.floor(__as_num) and __as_num > 0 and not string.find(__raw, '%a') then
		return __parse_query(__as_num)
	end

	local __lower = string.lower(__raw)

	for _, __p in ipairs(Players:GetPlayers()) do
		if string.lower(__p.Name) == __lower or string.lower(__p.DisplayName) == __lower then
			return __p.Name, __p.UserId, __p
		end
	end

	for _, __p in ipairs(Players:GetPlayers()) do
		if string.find(string.lower(__p.Name), __lower, 1, true)
			or string.find(string.lower(__p.DisplayName), __lower, 1, true)
		then
			return __p.Name, __p.UserId, __p
		end
	end

	local __ok, __user_id = pcall(function()
		return Players:GetUserIdFromNameAsync(__raw)
	end)

	if __ok and type(__user_id) == 'number' and __user_id > 0 then
		for _, __p in ipairs(Players:GetPlayers()) do
			if __p.UserId == __user_id then
				return __p.Name, __user_id, __p
			end
		end

		local __name_ok, __name = pcall(function()
			return Players:GetNameFromUserIdAsync(__user_id)
		end)

		return (if __name_ok and type(__name) == 'string' then __name else __raw), __user_id, nil
	end

	return nil, nil, nil
end

local function __desc_from_live(__player: Player): HumanoidDescription?
	local __char = __wait_character(__player, 2)
	local __hum = __humanoid(__char)

	if not __hum then
		return nil
	end

	local __ok, __desc = pcall(function()
		return __hum:GetAppliedDescription()
	end)

	if __ok and __desc and __desc:IsA('HumanoidDescription') then
		return __desc
	end

	return nil
end

local function __desc_from_user_id(__user_id: number): (HumanoidDescription?, string?)
	local __ok, __desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(__user_id)
	end)

	if __ok and __desc and __desc:IsA('HumanoidDescription') then
		return __desc, nil
	end

	return nil, 'catalog description failed · ' .. tostring(__user_id)
end

local function __get_objects(__asset_id: number): { Instance }
	local __uri = __asset_uri(__asset_id)
	local __out = {}

	local __ok, __objs = pcall(function()
		return (game :: any):GetObjects(__uri)
	end)

	if __ok and type(__objs) == 'table' then
		for _, __inst in ipairs(__objs) do
			if typeof(__inst) == 'Instance' then
				table.insert(__out, __inst)
			end
		end

		if #__out > 0 then
			return __out
		end
	end

	local __ok2, __local = pcall(function()
		return Service.InsertService:LoadLocalAsset(__uri)
	end)

	if __ok2 and typeof(__local) == 'Instance' then
		table.insert(__out, __local)
	end

	return __out
end

local function __split_csv_ids(__csv: string): { number }
	local __ids = {}
	local __seen: { [number]: boolean } = {}

	for __piece in string.gmatch(tostring(__csv or ''), '[^%,]+') do
		local __n = tonumber(__trim(__piece))

		if __n and __n > 0 then
			local __id = math.floor(__n)

			if not __seen[__id] then
				__seen[__id] = true
				table.insert(__ids, __id)
			end
		end
	end

	return __ids
end

local function __collect_accessory_ids(__desc: HumanoidDescription): { number }
	local __ids = {}
	local __seen: { [number]: boolean } = {}

	local function __push(__id: number)
		if __id > 0 and not __seen[__id] then
			__seen[__id] = true
			table.insert(__ids, __id)
		end
	end

	-- modern API
	pcall(function()
		local __list = (__desc :: any):GetAccessories(true)

		if type(__list) == 'table' then
			for _, __item in ipairs(__list) do
				if type(__item) == 'table' then
					local __aid = tonumber((__item :: any).AssetId or (__item :: any).assetId)

					if __aid then
						__push(math.floor(__aid))
					end
				elseif typeof(__item) == 'Instance' then
					local __aid = tonumber((__item :: any).AssetId)

					if __aid then
						__push(math.floor(__aid))
					end
				end
			end
		end
	end)

	-- also layered / false flag
	pcall(function()
		local __list = (__desc :: any):GetAccessories(false)

		if type(__list) == 'table' then
			for _, __item in ipairs(__list) do
				if type(__item) == 'table' then
					local __aid = tonumber((__item :: any).AssetId or (__item :: any).assetId)

					if __aid then
						__push(math.floor(__aid))
					end
				elseif typeof(__item) == 'Instance' then
					local __aid = tonumber((__item :: any).AssetId)

					if __aid then
						__push(math.floor(__aid))
					end
				end
			end
		end
	end)

	local __fields = {
		__desc.HatAccessory,
		__desc.HairAccessory,
		__desc.FaceAccessory,
		__desc.NeckAccessory,
		__desc.ShouldersAccessory,
		__desc.FrontAccessory,
		__desc.BackAccessory,
		__desc.WaistAccessory,
	}

	for _, __field in ipairs(__fields) do
		for _, __id in ipairs(__split_csv_ids(__field)) do
			__push(__id)
		end
	end

	return __ids
end

local function __find_attachment(__root: Instance, __name: string): Attachment?
	local __direct = __root:FindFirstChild(__name, true)

	if __direct and __direct:IsA('Attachment') then
		return __direct
	end

	return nil
end

local function __prepare_handle(__handle: BasePart): ()
	__handle.Anchored = false
	__handle.CanCollide = false
	__handle.CanTouch = false
	__handle.CanQuery = false
	__handle.Massless = true
	pcall(function()
		__handle.CastShadow = true
	end)

	-- strip old welds so we can rebind cleanly
	for _, __c in ipairs(__handle:GetChildren()) do
		if __c:IsA('Weld') or __c:IsA('WeldConstraint') or __c.Name == 'AccessoryWeld' then
			__c:Destroy()
		end
	end
end

local function __weld_accessory(__char: Model, __acc: Accessory | Hat): boolean
	local __handle = __acc:FindFirstChild('Handle')

	if not __handle or not __handle:IsA('BasePart') then
		-- still parent; better than drop
		__acc.Parent = __char

		return __acc.Parent == __char
	end

	__prepare_handle(__handle)

	local __hum = __humanoid(__char)

	-- 1) native AddAccessory (best when it works)
	if __hum then
		__acc.Parent = game -- must not already be under character for some clients
		local __ok = pcall(function()
			__hum:AddAccessory(__acc)
		end)

		if __ok and __acc.Parent == __char then
			local __weld = __handle:FindFirstChild('AccessoryWeld') or __handle:FindFirstChildOfClass('Weld')

			if __weld then
				return true
			end
		end
	end

	-- 2) attachment-based weld (R6 / R15 rigid)
	__acc.Parent = __char

	local __acc_att: Attachment? = nil

	for _, __c in ipairs(__handle:GetChildren()) do
		if __c:IsA('Attachment') then
			__acc_att = __c
			break
		end
	end

	if not __acc_att then
		for _, __c in ipairs(__acc:GetDescendants()) do
			if __c:IsA('Attachment') and __c.Parent == __handle then
				__acc_att = __c
				break
			end
		end
	end

	local __body_att: Attachment? = nil

	if __acc_att then
		__body_att = __find_attachment(__char, __acc_att.Name)
	end

	-- common fallbacks by accessory type
	if not __body_att then
		local __atype = ''

		pcall(function()
			if __acc:IsA('Accessory') then
				__atype = tostring(__acc.AccessoryType)
			end
		end)

		local __prefer = {
			'HatAttachment',
			'HairAttachment',
			'FaceFrontAttachment',
			'FaceCenterAttachment',
			'NeckAttachment',
			'NeckRigAttachment',
			'LeftCollarAttachment',
			'RightCollarAttachment',
			'BodyFrontAttachment',
			'BodyBackAttachment',
			'WaistFrontAttachment',
			'WaistCenterAttachment',
			'WaistBackAttachment',
			'FaceAccessoryAttachment',
		}

		if string.find(__atype, 'Hair') then
			__prefer = { 'HairAttachment', 'HatAttachment', 'FaceCenterAttachment' }
		elseif string.find(__atype, 'Face') then
			__prefer = { 'FaceFrontAttachment', 'FaceCenterAttachment', 'HatAttachment' }
		elseif string.find(__atype, 'Back') then
			__prefer = { 'BodyBackAttachment', 'WaistBackAttachment' }
		elseif string.find(__atype, 'Waist') then
			__prefer = { 'WaistCenterAttachment', 'WaistFrontAttachment', 'BodyFrontAttachment' }
		elseif string.find(__atype, 'Neck') then
			__prefer = { 'NeckAttachment', 'NeckRigAttachment' }
		end

		for _, __name in ipairs(__prefer) do
			__body_att = __find_attachment(__char, __name)

			if __body_att then
				break
			end
		end
	end

	if not __body_att then
		local __head = __char:FindFirstChild('Head')

		if __head then
			__body_att = __head:FindFirstChild('HatAttachment') :: Attachment?
				or __head:FindFirstChild('HairAttachment') :: Attachment?
				or __head:FindFirstChildOfClass('Attachment')
		end
	end

	if __body_att and __body_att.Parent and __body_att.Parent:IsA('BasePart') then
		local __weld = Instance.new('Weld')
		__weld.Name = 'AccessoryWeld'
		__weld.Part0 = __body_att.Parent
		__weld.Part1 = __handle

		if __acc_att then
			__weld.C0 = __body_att.CFrame
			__weld.C1 = __acc_att.CFrame
		else
			__weld.C0 = CFrame.new(0, 0.5, 0)
			__weld.C1 = CFrame.new()
		end

		__weld.Parent = __handle

		return true
	end

	-- 3) last resort: weld to Head
	local __head = __char:FindFirstChild('Head')

	if __head and __head:IsA('BasePart') then
		local __weld = Instance.new('Weld')
		__weld.Name = 'AccessoryWeld'
		__weld.Part0 = __head
		__weld.Part1 = __handle
		__weld.C0 = CFrame.new(0, 0.6, 0)
		__weld.C1 = CFrame.new()
		__weld.Parent = __handle

		return true
	end

	return __acc.Parent == __char
end

local function __extract_accessories(__root: Instance): { Accessory | Hat }
	local __list: { Accessory | Hat } = {}

	if __root:IsA('Accessory') or __root:IsA('Hat') then
		table.insert(__list, __root :: any)

		return __list
	end

	for _, __c in ipairs(__root:GetChildren()) do
		if __c:IsA('Accessory') or __c:IsA('Hat') then
			table.insert(__list, __c :: any)
		end
	end

	if #__list == 0 then
		for _, __c in ipairs(__root:GetDescendants()) do
			if __c:IsA('Accessory') or __c:IsA('Hat') then
				table.insert(__list, __c :: any)
			end
		end
	end

	return __list
end

local function __attach_accessory_instance(__char: Model, __acc: Accessory | Hat, __seen_names: { [string]: boolean }): boolean
	local __name = __acc.Name

	if __seen_names[__name] then
		-- allow duplicate names with suffix
		local __i = 2

		while __seen_names[__name .. '_' .. tostring(__i)] do
			__i += 1
		end

		__name = __name .. '_' .. tostring(__i)
		__acc.Name = __name
	end

	local __clone = __acc:Clone()
	__clone.Name = __name

	local __ok = __weld_accessory(__char, __clone :: any)

	if __ok then
		__seen_names[__name] = true
	else
		pcall(function()
			__clone:Destroy()
		end)
	end

	return __ok
end

local function __load_accessories_by_ids(__char: Model, __ids: { number }, __seen: { [string]: boolean }): number
	local __n = 0

	for _, __id in ipairs(__ids) do
		local __objs = __get_objects(__id)

		for _, __inst in ipairs(__objs) do
			for _, __acc in ipairs(__extract_accessories(__inst)) do
				if __attach_accessory_instance(__char, __acc, __seen) then
					__n += 1
				end
			end
		end
	end

	return __n
end

local function __clear_visuals(__char: Model): ()
	for _, __c in ipairs(__char:GetChildren()) do
		if __c:IsA('Accessory')
			or __c:IsA('Hat')
			or __c:IsA('Shirt')
			or __c:IsA('Pants')
			or __c:IsA('ShirtGraphic')
			or __c:IsA('BodyColors')
			or __c:IsA('CharacterMesh')
		then
			__c:Destroy()
		end
	end

	local __head = __char:FindFirstChild('Head')

	if __head then
		for _, __d in ipairs(__head:GetChildren()) do
			if __d:IsA('Decal') then
				__d:Destroy()
			end
		end
	end
end

local function __apply_clothing_and_body(__char: Model, __desc: HumanoidDescription): number
	local __n = 0

	if __desc.Shirt and __desc.Shirt > 0 then
		local __shirt = Instance.new('Shirt')
		__shirt.Name = 'Shirt'
		__shirt.ShirtTemplate = __asset_uri(__desc.Shirt)
		__shirt.Parent = __char
		__n += 1
	end

	if __desc.Pants and __desc.Pants > 0 then
		local __pants = Instance.new('Pants')
		__pants.Name = 'Pants'
		__pants.PantsTemplate = __asset_uri(__desc.Pants)
		__pants.Parent = __char
		__n += 1
	end

	if __desc.GraphicTShirt and __desc.GraphicTShirt > 0 then
		local __g = Instance.new('ShirtGraphic')
		__g.Name = 'Shirt Graphic'
		__g.Graphic = __asset_uri(__desc.GraphicTShirt)
		__g.Parent = __char
		__n += 1
	end

	local __bc = Instance.new('BodyColors')
	__bc.Name = 'Body Colors'
	__bc.HeadColor3 = __desc.HeadColor
	__bc.TorsoColor3 = __desc.TorsoColor
	__bc.LeftArmColor3 = __desc.LeftArmColor
	__bc.RightArmColor3 = __desc.RightArmColor
	__bc.LeftLegColor3 = __desc.LeftLegColor
	__bc.RightLegColor3 = __desc.RightLegColor
	__bc.Parent = __char
	__n += 1

	local __head = __char:FindFirstChild('Head')

	if __head and __desc.Face and __desc.Face > 0 then
		local __face = Instance.new('Decal')
		__face.Name = 'face'
		__face.Face = Enum.NormalId.Front
		__face.Texture = __asset_uri(__desc.Face)
		__face.Parent = __head
		__n += 1
	elseif __head then
		-- keep a default face decal if description has 0
		local __face = Instance.new('Decal')
		__face.Name = 'face'
		__face.Face = Enum.NormalId.Front
		__face.Texture = 'rbxasset://textures/face.png'
		__face.Parent = __head
	end

	return __n
end

local function __apply_packages(__char: Model, __desc: HumanoidDescription): number
	local __n = 0
	local __packages = {
		__desc.Head,
		__desc.Torso,
		__desc.LeftArm,
		__desc.RightArm,
		__desc.LeftLeg,
		__desc.RightLeg,
	}

	for _, __pid in ipairs(__packages) do
		if type(__pid) == 'number' and __pid > 0 then
			for _, __inst in ipairs(__get_objects(__pid)) do
				if __inst:IsA('CharacterMesh') then
					__inst.Parent = __char
					__n += 1
				else
					for _, __ch in ipairs(__inst:GetDescendants()) do
						if __ch:IsA('CharacterMesh') then
							__ch:Clone().Parent = __char
							__n += 1
						end
					end
				end
			end
		end
	end

	return __n
end

local function __copy_base_from_model(__char: Model, __model: Model): number
	local __n = 0
	local __head = __char:FindFirstChild('Head')

	for _, __c in ipairs(__model:GetChildren()) do
		if __c:IsA('Shirt')
			or __c:IsA('Pants')
			or __c:IsA('ShirtGraphic')
			or __c:IsA('BodyColors')
			or __c:IsA('CharacterMesh')
		then
			__c:Clone().Parent = __char
			__n += 1
		elseif __c.Name == 'Head' and __head then
			local __face = __c:FindFirstChild('face') or __c:FindFirstChildOfClass('Decal')

			if __face and __face:IsA('Decal') then
				__face:Clone().Parent = __head
				__n += 1
			end
		end
	end

	return __n
end

local function __copy_accessories_from_model(__char: Model, __model: Model, __seen: { [string]: boolean }): number
	local __n = 0

	for _, __acc in ipairs(__extract_accessories(__model)) do
		if __attach_accessory_instance(__char, __acc, __seen) then
			__n += 1
		end
	end

	return __n
end

local function __copy_accessories_from_character(__char: Model, __source: Model, __seen: { [string]: boolean }): number
	local __n = 0

	for _, __acc in ipairs(__extract_accessories(__source)) do
		if __attach_accessory_instance(__char, __acc, __seen) then
			__n += 1
		end
	end

	return __n
end

local function __apply_appearance(__desc: HumanoidDescription, __live_char: Model?): (boolean, string)
	local __char = __wait_character(LocalPlayer, 5)

	if not __char then
		return false, 'no local character'
	end

	local __hum = __humanoid(__char)

	if not __hum then
		return false, 'no local humanoid'
	end

	local __rig = __hum.RigType
	local __work_desc = __clone_desc(__desc) or __desc
	local __seen_acc: { [string]: boolean } = {}
	local __stats = {
		base = 0,
		acc_live = 0,
		acc_model = 0,
		acc_ids = 0,
		packages = 0,
	}

	-- build reference model (same rig) for clothing / packages / some accs
	local __model: Model? = nil
	local __ok_model, __built = pcall(function()
		return Players:CreateHumanoidModelFromDescription(__work_desc, __rig)
	end)

	if __ok_model and typeof(__built) == 'Instance' and __built:IsA('Model') then
		__model = __built
	end

	__clear_visuals(__char)

	-- clothing / body / face / packages from model first
	if __model then
		__stats.base = __copy_base_from_model(__char, __model)
	end

	-- always reinforce clothing from description (model can miss graphic tee etc.)
	if not __char:FindFirstChildOfClass('Shirt') or not __char:FindFirstChildOfClass('Pants') or not __char:FindFirstChildOfClass('BodyColors') then
		__stats.base += __apply_clothing_and_body(__char, __work_desc)
	else
		-- still ensure graphic tee / face if missing
		if __work_desc.GraphicTShirt and __work_desc.GraphicTShirt > 0 and not __char:FindFirstChildOfClass('ShirtGraphic') then
			local __g = Instance.new('ShirtGraphic')
			__g.Name = 'Shirt Graphic'
			__g.Graphic = __asset_uri(__work_desc.GraphicTShirt)
			__g.Parent = __char
			__stats.base += 1
		end
	end

	if not __char:FindFirstChildWhichIsA('CharacterMesh') then
		__stats.packages = __apply_packages(__char, __work_desc)
	end

	-- ACCESSORIES — always multi-source (this was the bug: skipped when clothing count >= 3)
	-- 1) live character in server (most accurate)
	if __live_char then
		__stats.acc_live = __copy_accessories_from_character(__char, __live_char, __seen_acc)
	end

	-- 2) temp model accessories
	if __model then
		__stats.acc_model = __copy_accessories_from_model(__char, __model, __seen_acc)
	end

	-- 3) force-load every accessory asset id from description
	local __acc_ids = __collect_accessory_ids(__work_desc)
	__stats.acc_ids = __load_accessories_by_ids(__char, __acc_ids, __seen_acc)

	if __model then
		pcall(function()
			__model:Destroy()
		end)
	end

	local __acc_total = __stats.acc_live + __stats.acc_model + __stats.acc_ids
	local __total = __stats.base + __stats.packages + __acc_total

	if __total <= 0 then
		return false, 'could not apply visuals on client'
	end

	return true, string.format(
		'applied · acc %d (live %d / model %d / assets %d) · base %d',
		__acc_total,
		__stats.acc_live,
		__stats.acc_model,
		__stats.acc_ids,
		__stats.base + __stats.packages
	)
end

local function __snapshot_local(): (HumanoidDescription?, string?)
	local __char = __wait_character(LocalPlayer, 5)
	local __hum = __humanoid(__char)

	if __hum then
		local __ok, __desc = pcall(function()
			return __hum:GetAppliedDescription()
		end)

		if __ok and __desc and __desc:IsA('HumanoidDescription') then
			return __clone_desc(__desc) or __desc, nil
		end
	end

	local __ok2, __desc2 = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
	end)

	if __ok2 and __desc2 and __desc2:IsA('HumanoidDescription') then
		return __clone_desc(__desc2) or __desc2, nil
	end

	return nil, 'could not snapshot self'
end

local function __player_names(): { string }
	local __out = {}

	for _, __p in ipairs(Players:GetPlayers()) do
		if __p ~= LocalPlayer then
			table.insert(__out, __p.Name)
		end
	end

	table.sort(__out)

	return __out
end

function AvatarStealer:init(): AvatarStealer
	self.__target = ''
	self.__busy = false
	self.__library = nil

	if not self.__saved then
		task.defer(function()
			self:save_self()
		end)
	end

	return self
end

function AvatarStealer:save_self(): (boolean, string)
	local __desc, __err = __snapshot_local()

	if not __desc then
		return false, __err or 'save failed'
	end

	self.__saved = __desc

	return true, 'saved'
end

function AvatarStealer:steal(__target: string | number | Player): (boolean, string)
	if self.__busy then
		return false, 'busy'
	end

	self.__busy = true

	local __ok_run, __result_ok, __result_msg = pcall(function()
		if not self.__saved then
			self:save_self()
		end

		local __label, __user_id, __player = __parse_query(__target)

		if not __user_id then
			return false, 'user not found · use username / userId / profile URL'
		end

		local __desc: HumanoidDescription? = nil
		local __err: string? = nil
		local __live_char: Model? = nil
		local __source = 'catalog'

		if __player then
			__live_char = __wait_character(__player, 2)
			__desc = __desc_from_live(__player)

			if __desc then
				__source = 'live'
			end
		end

		if not __desc then
			__desc, __err = __desc_from_user_id(__user_id)
			__source = 'catalog'
		end

		if not __desc then
			return false, __err or 'no description'
		end

		local __applied, __apply_msg = __apply_appearance(__desc, __live_char)

		if not __applied then
			return false, __apply_msg
		end

		self.__target = __label or tostring(__user_id)

		local __where = if __player then 'in-server' else 'offline'

		return true, 'stole · ' .. self.__target .. ' · ' .. __where .. ' · ' .. __source .. ' · ' .. __apply_msg
	end)

	self.__busy = false

	if not __ok_run then
		return false, tostring(__result_ok)
	end

	return __result_ok :: boolean, __result_msg :: string
end

function AvatarStealer:restore(): (boolean, string)
	if self.__busy then
		return false, 'busy'
	end

	if not self.__saved then
		local __ok_save, __msg_save = self:save_self()

		if not __ok_save or not self.__saved then
			return false, __msg_save or 'nothing saved'
		end
	end

	self.__busy = true

	local __clone = __clone_desc(self.__saved :: HumanoidDescription) or self.__saved
	local __ok, __msg = __apply_appearance(__clone :: HumanoidDescription, nil)

	self.__busy = false

	if __ok then
		self.__target = ''
	end

	return __ok, if __ok then 'restored · ' .. __msg else __msg
end

function AvatarStealer:start(): ()
end

function AvatarStealer:stop(): ()
	self.__busy = false
end

function AvatarStealer:attach_ui(__library: any): ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	self.__library = __library

	local __self = self
	local __tab = __library:create_tab('Avatar', 'rbxassetid://10747373176')
	local __name_box_value = ''

	__tab:create_divider('Any username (online or offline)')

	__tab:create_textbox({
		title = 'Username',
		placeholder = 'name / @name / userId / profile URL',
		callback = function(__text)
			__name_box_value = __trim(__text)
			__self.__target = __name_box_value

			if __name_box_value == '' then
				return
			end

			local __ok, __msg = __self:steal(__name_box_value)

			__notify(__self, __msg, if __ok then 'normal' else 'error')
		end,
	})

	__tab:create_button({
		title = 'Steal username now',
		callback = function()
			local __t = __trim(__name_box_value ~= '' and __name_box_value or __self.__target)

			if __t == '' then
				__notify(__self, 'type a username first (Enter on box)', 'warn')

				return
			end

			local __ok, __msg = __self:steal(__t)

			__notify(__self, __msg, if __ok then 'normal' else 'error')
		end,
	})

	__tab:create_divider('In this server')

	local __dropdown: any = nil
	local __names = __player_names()

	if #__names == 0 then
		__names = { '(no players)' }
	end

	if type(__tab.create_dropdown) == 'function' then
		__dropdown = __tab:create_dropdown({
			title = 'Player',
			options = __names,
			default = __names[1],
			multi_selection = false,
			callback = function(__value)
				if type(__value) == 'string' and __value ~= '(no players)' then
					__self.__target = __value
					__name_box_value = __value
				elseif type(__value) == 'table' and type(__value[1]) == 'string' then
					__self.__target = __value[1]
					__name_box_value = __value[1]
				end
			end,
		})
	end

	__tab:create_button({
		title = 'Refresh server list',
		callback = function()
			local __list = __player_names()

			if #__list == 0 then
				__list = { '(no players)' }
			end

			if __dropdown and type(__dropdown.Set) == 'function' then
				pcall(function()
					__dropdown:Set(__list[1])
				end)
			end

			if __list[1] ~= '(no players)' then
				__self.__target = __list[1]
				__name_box_value = __list[1]
			end

			local __count = 0

			for _, __n in ipairs(__list) do
				if __n ~= '(no players)' then
					__count += 1
				end
			end

			__notify(__self, 'server players · ' .. tostring(__count))
		end,
	})

	__tab:create_button({
		title = 'Steal selected player',
		callback = function()
			local __t = __self.__target

			if __t == '' or __t == '(no players)' then
				__notify(__self, 'pick a player first', 'warn')

				return
			end

			local __ok, __msg = __self:steal(__t)

			__notify(__self, __msg, if __ok then 'normal' else 'error')
		end,
	})

	__tab:create_divider('Self')

	__tab:create_button({
		title = 'Save my avatar',
		callback = function()
			local __ok, __msg = __self:save_self()

			__notify(__self, __msg, if __ok then 'normal' else 'error')
		end,
	})

	__tab:create_button({
		title = 'Restore my avatar',
		callback = function()
			local __ok, __msg = __self:restore()

			__notify(__self, __msg, if __ok then 'normal' else 'error')
		end,
	})
end

function AvatarStealer:destroy(): ()
	self:stop()
	self.__library = nil
end


export type FFlagApplyResult = {
	name: string,
	ok: boolean,
	backend: string?,
	before: string?,
	after: string?,
	err: string?,
}

export type FFlagBatchSummary = {
	ok: number,
	fail: number,
	skipped: number,
	total: number,
	results: { FFlagApplyResult },
}

export type FFlagInjector = {
	__library: any,
	__ready: boolean,
	__busy: boolean,
	__backend: string,
	__backends: { string },
	__setters: { any },
	__bulk_setter: any,
	__getter: any,
	__original: { [string]: string },
	__applied: { [string]: string },
	__custom_name: string,
	__custom_value: string,
	__paste_buf: string,
	__auto_reapply: boolean,
	__safe_mode: boolean,
	__reapply_conn: RBXScriptConnection?,
	__last_reapply: number,
	__chunk_size: number,
	__chunk_delay: number,

	init: (self: FFlagInjector) -> FFlagInjector,
	start: (self: FFlagInjector) -> (),
	stop: (self: FFlagInjector) -> (),
	attach_ui: (self: FFlagInjector, library: any) -> (),
	probe: (self: FFlagInjector) -> string,
	get: (self: FFlagInjector, name: string) -> (boolean, string?),
	set: (self: FFlagInjector, name: string, value: string | boolean | number, opts: { verify: boolean?, save_original: boolean?, retries: number? }?) -> FFlagApplyResult,
	apply_batch: (self: FFlagInjector, raw: string) -> FFlagBatchSummary,
	apply_map: (self: FFlagInjector, map: { [string]: string }) -> FFlagBatchSummary,
	restore_name: (self: FFlagInjector, name: string) -> FFlagApplyResult,
	restore_all: (self: FFlagInjector) -> { ok: number, fail: number },
	destroy: (self: FFlagInjector) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local RunService = Service.RunService
local HttpService = Service.HttpService

local __MAX_BATCH = 400
local __DEFAULT_CHUNK = 8
local __DEFAULT_DELAY = 0.03

local FFlagInjector: FFlagInjector = {
	__library = nil,
	__ready = false,
	__busy = false,
	__backend = 'none',
	__backends = {},
	__setters = {},
	__bulk_setter = nil,
	__getter = nil,
	__original = {},
	__applied = {},
	__custom_name = '',
	__custom_value = '',
	__paste_buf = '',
	__auto_reapply = true,
	__safe_mode = true,
	__reapply_conn = nil,
	__last_reapply = 0,
	__chunk_size = __DEFAULT_CHUNK,
	__chunk_delay = __DEFAULT_DELAY,
}
FFlagInjector.__index = FFlagInjector

local function __notify(__self: FFlagInjector, __content: string, __kind: string?): ()
	local __lib = __self.__library

	if type(__lib) == 'table' and type(__lib.notify) == 'function' then
		pcall(function()
			__lib:notify({
				title = 'FFlags',
				content = __content,
				duration = 2.8,
				notify_type = __kind or 'normal',
			})
		end)
	end
end

local function __trim(__s: any): string
	return (string.gsub(tostring(__s or ''), '^%s+', '')):gsub('%s+$', '')
end

local function __callable(__v: any): boolean
	return type(__v) == 'function'
end

local function __safe_call(__fn: any, ...: any): (boolean, any)
	if not __callable(__fn) then
		return false, 'not a function'
	end

	local __pack = table.pack(pcall(__fn, ...))

	if not __pack[1] then
		return false, __pack[2]
	end

	return true, table.unpack(__pack, 2, __pack.n)
end

local function __env_get(__name: string): any
	local __ok_g, __g = pcall(function()
		return getgenv and getgenv()
	end)

	if __ok_g and type(__g) == 'table' and __g[__name] ~= nil then
		return __g[__name]
	end

	local __ok_s, __s = pcall(function()
		return getrenv and getrenv()
	end)

	if __ok_s and type(__s) == 'table' and __s[__name] ~= nil then
		return __s[__name]
	end

	local __ok_r, __r = pcall(function()
		return rawget(_G, __name)
	end)

	if __ok_r then
		return __r
	end

	local __ok_f, __f = pcall(function()
		return getfenv and getfenv()
	end)

	if __ok_f and type(__f) == 'table' and __f[__name] ~= nil then
		return __f[__name]
	end

	return nil
end

local function __normalize_value(__raw: string | boolean | number): string
	if type(__raw) == 'boolean' then
		return if __raw then 'true' else 'false'
	end

	if type(__raw) == 'number' then
		if __raw ~= __raw or __raw == math.huge or __raw == -math.huge then
			return '0'
		end

		if __raw == math.floor(__raw) then
			return tostring(math.floor(__raw))
		end

		return tostring(__raw)
	end

	local __s = __trim(__raw)

	-- strip wrapping quotes
	if (#__s >= 2) and ((string.sub(__s, 1, 1) == '"' and string.sub(__s, -1) == '"') or (string.sub(__s, 1, 1) == "'" and string.sub(__s, -1) == "'")) then
		__s = string.sub(__s, 2, -2)
		__s = __trim(__s)
	end

	local __lower = string.lower(__s)

	if __lower == '1' or __lower == 'true' or __lower == 'yes' or __lower == 'on' then
		return 'true'
	end

	if __lower == '0' or __lower == 'false' or __lower == 'no' or __lower == 'off' then
		return 'false'
	end

	return __s
end

local function __valid_flag_name(__name: string): boolean
	if __name == '' or #__name > 128 then
		return false
	end

	-- FFlag / DFInt / FString / FInt / DFFlag / DFLog / FLog ...
	if string.match(__name, '^[%a_][%w_]*$') == nil then
		return false
	end

	return true
end

local function __values_equal(__a: string?, __b: string?): boolean
	if __a == nil or __b == nil then
		return false
	end

	local __la = string.lower(__trim(__a))
	local __lb = string.lower(__trim(__b))

	if __la == __lb then
		return true
	end

	local __na = tonumber(__la)
	local __nb = tonumber(__lb)

	if __na and __nb then
		return __na == __nb
	end

	local __ba = if __la == 'true' or __la == '1' then true elseif __la == 'false' or __la == '0' then false else nil
	local __bb = if __lb == 'true' or __lb == '1' then true elseif __lb == 'false' or __lb == '0' then false else nil

	if __ba ~= nil and __bb ~= nil then
		return __ba == __bb
	end

	return false
end

local function __resolve_getter(): any
	local __list = {
		function()
			return getfflag
		end,
		function()
			return __env_get('getfflag')
		end,
		function()
			return __env_get('GetFFlag')
		end,
		function()
			local __d = __env_get('debug')

			if type(__d) == 'table' then
				return __d.getfflag
			end

			return nil
		end,
		function()
			return debug and (debug :: any).getfflag
		end,
	}

	for _, __factory in ipairs(__list) do
		local __ok, __fn = pcall(__factory)

		if __ok and __callable(__fn) then
			return __fn
		end
	end

	return nil
end

local function __resolve_setters(): ({ any }, any, { string })
	local __setters = {}
	local __labels = {}
	local __bulk = nil

	local function __add(__label: string, __fn: any)
		if __callable(__fn) then
			table.insert(__setters, { label = __label, fn = __fn })
			table.insert(__labels, __label)
		end
	end

	pcall(function()
		__add('setfflag', setfflag)
	end)

	__add('getgenv.setfflag', __env_get('setfflag'))
	__add('setfastflag', __env_get('setfastflag') or __env_get('SetFastFlag'))
	__add('setflag', __env_get('setflag') or __env_get('SetFlag'))

	pcall(function()
		if type(debug) == 'table' then
			__add('debug.setfflag', (debug :: any).setfflag)
		end
	end)

	local __dbg = __env_get('debug')

	if type(__dbg) == 'table' then
		__add('env.debug.setfflag', __dbg.setfflag)
	end

	local __bulk_fn = __env_get('setfflags') or __env_get('SetFFlags')

	pcall(function()
		if __callable(setfflags) then
			__bulk_fn = setfflags
		end
	end)

	if __callable(__bulk_fn) then
		__bulk = __bulk_fn
		table.insert(__labels, 'setfflags(bulk)')
	end

	return __setters, __bulk, __labels
end

local function __try_get(__self: FFlagInjector, __name: string): (boolean, string?)
	local __fn = __self.__getter

	if not __callable(__fn) then
		__fn = __resolve_getter()
		__self.__getter = __fn
	end

	if not __callable(__fn) then
		return false, nil
	end

	local __ok, __val = __safe_call(__fn, __name)

	if __ok and __val ~= nil then
		return true, tostring(__val)
	end

	return false, nil
end

local function __try_set_one(__self: FFlagInjector, __name: string, __value: string): (boolean, string?, string?)
	-- bulk single-key first if that's the only path
	if __callable(__self.__bulk_setter) and #__self.__setters == 0 then
		local __ok, __err = __safe_call(__self.__bulk_setter, { [__name] = __value })

		if __ok then
			return true, 'setfflags', nil
		end

		return false, nil, tostring(__err)
	end

	for _, __item in ipairs(__self.__setters) do
		local __ok, __err = __safe_call(__item.fn, __name, __value)

		if __ok then
			return true, __item.label, nil
		end

		-- some APIs want (name, value) as strings only — already strings
		-- try tostring again is noop
		local _ = __err
	end

	if __callable(__self.__bulk_setter) then
		local __ok, __err = __safe_call(__self.__bulk_setter, { [__name] = __value })

		if __ok then
			return true, 'setfflags', nil
		end

		return false, nil, tostring(__err)
	end

	return false, nil, 'no backend'
end

local function __try_set_bulk(__self: FFlagInjector, __map: { [string]: string }): (boolean, string?)
	if not __callable(__self.__bulk_setter) then
		return false, 'no bulk'
	end

	-- primary: table map
	local __ok, __err = __safe_call(__self.__bulk_setter, __map)

	if __ok then
		return true, nil
	end

	-- some executors want array of pairs
	local __arr = {}

	for __n, __v in pairs(__map) do
		table.insert(__arr, { __n, __v })
	end

	local __ok2, __err2 = __safe_call(__self.__bulk_setter, __arr)

	if __ok2 then
		return true, nil
	end

	return false, tostring(__err2 or __err)
end

-- ─── multi-format parser ───────────────────────────────────────────

local function __push_pair(
	__out: { { name: string, value: string } },
	__seen: { [string]: number },
	__name: any,
	__value: any
): boolean
	local __n = __trim(__name)

	-- JSON null → skip (not a usable fflag value)
	if __value == nil then
		return false
	end

	if type(__value) == 'string' and (string.lower(__trim(__value)) == 'null' or __trim(__value) == '') then
		-- empty / null strings skipped for safety
		if string.lower(__trim(__value)) == 'null' then
			return false
		end
	end

	local __v = __normalize_value(__value :: any)

	if not __valid_flag_name(__n) or __v == '' then
		return false
	end

	local __idx = __seen[__n]

	if __idx then
		__out[__idx].value = __v
	else
		table.insert(__out, { name = __n, value = __v })
		__seen[__n] = #__out
	end

	return true
end

local function __parse_json_map(__text: string): { [string]: any }?
	local __src = __trim(__text)

	-- tolerate trailing commas which break JSONDecode
	__src = string.gsub(__src, ',%s*}', '}')
	__src = string.gsub(__src, ',%s*%]', ']')

	local __ok, __decoded = pcall(function()
		return HttpService:JSONDecode(__src)
	end)

	if not __ok or type(__decoded) ~= 'table' then
		return nil
	end

	return __decoded
end

local function __ingest_table(
	__out: { { name: string, value: string } },
	__seen: { [string]: number },
	__tbl: { [any]: any }
): ()
	-- array of {name,value} or {Name=,Value=} or ["Flag","val"]
	local __is_array = (#__tbl > 0)

	if __is_array then
		for _, __item in ipairs(__tbl) do
			if type(__item) == 'table' then
				local __n = (__item :: any).name or (__item :: any).Name or (__item :: any).flag or (__item :: any).Flag or (__item :: any)[1]
				local __v = (__item :: any).value or (__item :: any).Value or (__item :: any).val or (__item :: any)[2]

				if __n ~= nil and __v ~= nil then
					__push_pair(__out, __seen, __n, __v)
				else
					-- nested map inside array
					for __k, __val in pairs(__item) do
						if type(__k) == 'string' then
							__push_pair(__out, __seen, __k, __val)
						end
					end
				end
			end
		end

		return
	end

	for __k, __v in pairs(__tbl) do
		if type(__k) == 'string' then
			-- ClientAppSettings sometimes nests under FFlag* only at top
			if type(__v) == 'table' then
				-- skip deep nests except simple maps of flags
				for __k2, __v2 in pairs(__v) do
					if type(__k2) == 'string' and (type(__v2) == 'string' or type(__v2) == 'number' or type(__v2) == 'boolean') then
						__push_pair(__out, __seen, __k2, __v2)
					end
				end
			else
				__push_pair(__out, __seen, __k, __v)
			end
		end
	end
end

local function __parse_line_pair(__line: string): (string?, string?)
	local __piece = __trim(__line)

	if __piece == '' then
		return nil, nil
	end

	-- comments
	if string.sub(__piece, 1, 1) == '#' or string.sub(__piece, 1, 2) == '//' then
		return nil, nil
	end

	-- strip trailing commas / semicolons
	__piece = string.gsub(__piece, '[,;]+$', '')
	__piece = __trim(__piece)

	-- JSON line fragment "Name": value
	local __jn, __jv = string.match(__piece, '^"([%w_]+)"%s*:%s*(.-)%s*,?$')

	if __jn and __jv then
		__jv = __trim(__jv)
		__jv = string.gsub(__jv, ',$', '')
		__jv = __trim(__jv)

		if string.sub(__jv, 1, 1) == '"' and string.sub(__jv, -1) == '"' then
			__jv = string.sub(__jv, 2, -2)
		end

		return __jn, __jv
	end

	-- Name=value | Name:value | Name value
	local __eq = string.find(__piece, '=', 1, true)
	local __colon = string.find(__piece, ':', 1, true)
	local __sep: number? = nil
	local __sep_len = 1

	if __eq and __colon then
		__sep = math.min(__eq, __colon)
	else
		__sep = __eq or __colon
	end

	if __sep then
		local __n = __trim(string.sub(__piece, 1, __sep - 1))
		local __v = __trim(string.sub(__piece, __sep + __sep_len))

		-- clean name quotes
		__n = string.gsub(__n, '^["\']', '')
		__n = string.gsub(__n, '["\']$', '')

		return __n, __v
	end

	-- Name true/false/123
	local __n2, __v2 = string.match(__piece, '^([%a_][%w_]*)%s+(%S+)$')

	if __n2 and __v2 then
		return __n2, __v2
	end

	return nil, nil
end

local function __parse_batch(__raw: string): { { name: string, value: string } }
	local __out: { { name: string, value: string } } = {}
	local __seen: { [string]: number } = {}
	local __text = __trim(__raw)

	if __text == '' then
		return __out
	end

	-- 1) full JSON document
	if string.sub(__text, 1, 1) == '{' or string.sub(__text, 1, 1) == '[' then
		local __tbl = __parse_json_map(__text)

		if __tbl then
			__ingest_table(__out, __seen, __tbl)

			if #__out > 0 then
				return __out
			end
		end
	end

	-- 2) try wrap as object if looks like JSON body without braces
	if string.find(__text, '"%s*:') then
		local __wrapped = __text

		if string.sub(__wrapped, 1, 1) ~= '{' then
			__wrapped = '{' .. __wrapped

			if string.sub(__wrapped, -1) == ',' then
				__wrapped = string.sub(__wrapped, 1, -2)
			end

			__wrapped = __wrapped .. '}'
		end

		local __tbl = __parse_json_map(__wrapped)

		if __tbl then
			__ingest_table(__out, __seen, __tbl)

			if #__out > 0 then
				return __out
			end
		end
	end

	-- 3) line-oriented (newlines / semicolons). Keep commas inside values.
	local __normalized = string.gsub(__text, '\r\n', '\n')
	__normalized = string.gsub(__normalized, '\r', '\n')
	__normalized = string.gsub(__normalized, ';', '\n')

	for __line in string.gmatch(__normalized .. '\n', '([^\n]*)\n') do
		local __n, __v = __parse_line_pair(__line)

		if __n and __v then
			__push_pair(__out, __seen, __n, __v)
		end
	end

	-- 4) if still empty, try comma-separated pairs Name=value, Name2=value2
	if #__out == 0 and string.find(__text, '=', 1, true) then
		for __piece in string.gmatch(__text .. ',', '([^,]+),') do
			local __n, __v = __parse_line_pair(__piece)

			if __n and __v then
				__push_pair(__out, __seen, __n, __v)
			end
		end
	end

	return __out
end

-- ─── public API ────────────────────────────────────────────────────

function FFlagInjector:probe(): string
	local __ok, __err = pcall(function()
		local __setters, __bulk, __labels = __resolve_setters()
		self.__setters = __setters
		self.__bulk_setter = __bulk
		self.__backends = __labels
		self.__getter = __resolve_getter()

		if #__setters > 0 then
			self.__backend = __setters[1].label
		elseif __bulk then
			self.__backend = 'setfflags'
		else
			self.__backend = 'none'
		end

		self.__ready = self.__backend ~= 'none'
	end)

	if not __ok then
		self.__ready = false
		self.__backend = 'none'
		warn('[euphoria fflags] probe ' .. tostring(__err))
	end

	return self.__backend
end

function FFlagInjector:get(__name: string): (boolean, string?)
	return __try_get(self, __trim(__name))
end

function FFlagInjector:set(
	__name: string,
	__value: string | boolean | number,
	__opts: { verify: boolean?, save_original: boolean?, retries: number? }?
): FFlagApplyResult
	local __ok_outer, __result = pcall(function()
		__opts = __opts or {}

		local __flag = __trim(__name)
		local __normalized = __normalize_value(__value)
		local __save_original = if __opts.save_original == nil then true else __opts.save_original
		local __verify = if __opts.verify == nil then true else __opts.verify
		local __retries = math.clamp(tonumber(__opts.retries) or (if self.__safe_mode then 2 else 1), 1, 4)

		if not __valid_flag_name(__flag) then
			return { name = __flag, ok = false, err = 'invalid name' }
		end

		if __normalized == '' then
			return { name = __flag, ok = false, err = 'empty value' }
		end

		if not self.__ready then
			self:probe()
		end

		if not self.__ready then
			return { name = __flag, ok = false, err = 'no setfflag backend' }
		end

		if __save_original and self.__original[__flag] == nil then
			local __ok_get, __before = __try_get(self, __flag)

			if __ok_get and __before ~= nil then
				self.__original[__flag] = __before
			end
		end

		local __before = self.__original[__flag]
		local __backend: string? = nil
		local __last_err = 'set failed'

		for __i = 1, __retries do
			local __ok_set, __b, __err = __try_set_one(self, __flag, __normalized)

			if __ok_set then
				__backend = __b
				__last_err = ''
				break
			end

			__last_err = tostring(__err or 'set failed')

			if __i < __retries then
				task.wait(0.02)
			end
		end

		if __backend == nil then
			return {
				name = __flag,
				ok = false,
				before = __before,
				err = __last_err,
			}
		end

		-- soft second poke for sticky flags (safe mode)
		if self.__safe_mode then
			pcall(function()
				__try_set_one(self, __flag, __normalized)
			end)
		end

		self.__applied[__flag] = __normalized

		local __after: string? = nil

		if __verify then
			local __ok_after, __val_after = __try_get(self, __flag)

			if __ok_after then
				__after = __val_after
			end

			if __after ~= nil and not __values_equal(__after, __normalized) then
				-- one more forced set
				__try_set_one(self, __flag, __normalized)
				task.wait(0.02)

				local __ok2, __val2 = __try_get(self, __flag)

				if __ok2 then
					__after = __val2
				end

				if __after ~= nil and not __values_equal(__after, __normalized) then
					-- still keep as applied (some clients lie on read) but mark warn via after
					return {
						name = __flag,
						ok = true,
						backend = __backend,
						before = __before,
						after = __after,
						err = 'applied (readback mismatch)',
					}
				end
			end
		end

		return {
			name = __flag,
			ok = true,
			backend = __backend,
			before = __before,
			after = __after or __normalized,
		}
	end)

	if not __ok_outer then
		return {
			name = tostring(__name),
			ok = false,
			err = 'crash guarded · ' .. tostring(__result),
		}
	end

	return __result :: FFlagApplyResult
end

function FFlagInjector:apply_map(__map: { [string]: string }): FFlagBatchSummary
	local __pairs = {}

	for __n, __v in pairs(__map) do
		table.insert(__pairs, { name = __n, value = __v })
	end

	table.sort(__pairs, function(__a, __b)
		return __a.name < __b.name
	end)

	-- reuse batch path via synthetic raw? better inline safe loop
	local __results: { FFlagApplyResult } = {}
	local __ok_n = 0
	local __fail_n = 0
	local __skipped = 0

	if not self.__ready then
		self:probe()
	end

	-- try true bulk first (fast + safer for large sets)
	if __callable(self.__bulk_setter) and #__pairs > 1 then
		local __bulk_map: { [string]: string } = {}
		local __ordered = {}

		for _, __p in ipairs(__pairs) do
			local __n = __trim(__p.name)
			local __v = __normalize_value(__p.value)

			if __valid_flag_name(__n) and __v ~= '' then
				if self.__original[__n] == nil then
					local __ok_g, __before = __try_get(self, __n)

					if __ok_g and __before ~= nil then
						self.__original[__n] = __before
					end
				end

				__bulk_map[__n] = __v
				table.insert(__ordered, __n)
			else
				__skipped += 1
			end
		end

		local __ok_bulk = __try_set_bulk(self, __bulk_map)

		if __ok_bulk then
			-- second bulk pass (sticky)
			if self.__safe_mode then
				task.wait(self.__chunk_delay)
				__try_set_bulk(self, __bulk_map)
			end

			for _, __n in ipairs(__ordered) do
				local __v = __bulk_map[__n]
				self.__applied[__n] = __v

				local __after: string? = nil
				local __ok_g, __val = __try_get(self, __n)

				if __ok_g then
					__after = __val
				end

				local __res: FFlagApplyResult = {
					name = __n,
					ok = true,
					backend = 'setfflags',
					before = self.__original[__n],
					after = __after or __v,
				}

				table.insert(__results, __res)
				__ok_n += 1
			end

			return {
				ok = __ok_n,
				fail = __fail_n,
				skipped = __skipped,
				total = #__pairs,
				results = __results,
			}
		end
	end

	-- chunked single applies (anti-crash)
	local __chunk = math.clamp(self.__chunk_size or __DEFAULT_CHUNK, 1, 32)
	local __delay = math.clamp(self.__chunk_delay or __DEFAULT_DELAY, 0, 0.2)
	local __count = 0

	for _, __p in ipairs(__pairs) do
		__count += 1

		if __count > __MAX_BATCH then
			__skipped += (#__pairs - __count + 1)
			table.insert(__results, {
				name = 'batch',
				ok = false,
				err = 'capped at ' .. tostring(__MAX_BATCH),
			})
			break
		end

		-- lighter verify in big maps
		local __verify = true

		if self.__safe_mode and #__pairs > 20 then
			__verify = (__count % 5 == 0) -- sample verify
		end

		local __res = self:set(__p.name, __p.value, {
			verify = __verify,
			save_original = true,
			retries = if self.__safe_mode then 2 else 1,
		})

		table.insert(__results, __res)

		if __res.ok then
			__ok_n += 1
		else
			__fail_n += 1
		end

		if __count % __chunk == 0 then
			task.wait(__delay)
		end
	end

	-- final reinforcement pass on applied map (no verify) — makes them "really" stick
	if self.__safe_mode and __ok_n > 0 then
		task.wait(__delay)

		local __reinforce = {}

		for __n, __v in pairs(self.__applied) do
			__reinforce[__n] = __v
		end

		if __callable(self.__bulk_setter) then
			__try_set_bulk(self, __reinforce)
		else
			local __i = 0

			for __n, __v in pairs(__reinforce) do
				__i += 1
				__try_set_one(self, __n, __v)

				if __i % __chunk == 0 then
					task.wait(__delay)
				end
			end
		end
	end

	return {
		ok = __ok_n,
		fail = __fail_n,
		skipped = __skipped,
		total = #__pairs,
		results = __results,
	}
end

function FFlagInjector:apply_batch(__raw: string): FFlagBatchSummary
	local __ok, __summary = pcall(function()
		local __pairs = __parse_batch(__raw)

		if #__pairs == 0 then
			return {
				ok = 0,
				fail = 1,
				skipped = 0,
				total = 0,
				results = {
					{ name = 'batch', ok = false, err = 'nothing parsed · check format' },
				},
			}
		end

		if #__pairs > __MAX_BATCH then
			local __cut = {}

			for __i = 1, __MAX_BATCH do
				__cut[__i] = __pairs[__i]
			end

			__pairs = __cut
		end

		local __map: { [string]: string } = {}

		for _, __p in ipairs(__pairs) do
			__map[__p.name] = __p.value
		end

		return self:apply_map(__map)
	end)

	if not __ok then
		return {
			ok = 0,
			fail = 1,
			skipped = 0,
			total = 0,
			results = {
				{ name = 'batch', ok = false, err = 'crash guarded · ' .. tostring(__summary) },
			},
		}
	end

	return __summary :: FFlagBatchSummary
end

function FFlagInjector:restore_name(__name: string): FFlagApplyResult
	local __flag = __trim(__name)
	local __original = self.__original[__flag]

	if __original == nil then
		return { name = __flag, ok = false, err = 'no snapshot' }
	end

	local __res = self:set(__flag, __original, { verify = true, save_original = false, retries = 2 })

	if __res.ok then
		self.__applied[__flag] = nil
	end

	return __res
end

function FFlagInjector:restore_all(): { ok: number, fail: number }
	local __ok_n = 0
	local __fail_n = 0
	local __map: { [string]: string } = {}

	for __name, __val in pairs(self.__original) do
		__map[__name] = __val
	end

	local __names = {}

	for __n in pairs(__map) do
		table.insert(__names, __n)
	end

	table.sort(__names)

	local __chunk = self.__chunk_size

	for __i, __name in ipairs(__names) do
		local __res = self:restore_name(__name)

		if __res.ok then
			__ok_n += 1
		else
			__fail_n += 1
		end

		if __i % __chunk == 0 then
			task.wait(self.__chunk_delay)
		end
	end

	return { ok = __ok_n, fail = __fail_n }
end

function FFlagInjector:init(): FFlagInjector
	self.__library = nil
	self.__busy = false
	self.__custom_name = ''
	self.__custom_value = ''
	self.__paste_buf = ''
	self.__auto_reapply = true
	self.__safe_mode = true
	self.__last_reapply = 0
	self.__chunk_size = __DEFAULT_CHUNK
	self.__chunk_delay = __DEFAULT_DELAY
	self.__applied = {}
	self.__original = self.__original or {}
	self.__setters = {}
	self.__bulk_setter = nil
	self.__getter = nil

	self:probe()

	return self
end

function FFlagInjector:start(): ()
	if self.__reapply_conn then
		return
	end

	self.__reapply_conn = RunService.Heartbeat:Connect(function()
		if not self.__auto_reapply or self.__busy then
			return
		end

		local __now = os.clock()

		if __now - self.__last_reapply < 4 then
			return
		end

		self.__last_reapply = __now

		local __ok, __err = pcall(function()
			local __map = {}
			local __n = 0

			for __name, __value in pairs(self.__applied) do
				__map[__name] = __value
				__n += 1
			end

			if __n == 0 then
				return
			end

			if __callable(self.__bulk_setter) then
				__try_set_bulk(self, __map)

				return
			end

			local __i = 0

			for __name, __value in pairs(__map) do
				local __ok_get, __current = __try_get(self, __name)

				if (not __ok_get) or (__current ~= nil and not __values_equal(__current, __value)) then
					__try_set_one(self, __name, __value)
				end

				__i += 1

				if __i % 10 == 0 then
					task.wait()
				end
			end
		end)

		if not __ok then
			warn('[euphoria fflags] reapply ' .. tostring(__err))
		end
	end)
end

function FFlagInjector:stop(): ()
	self.__auto_reapply = false

	if self.__reapply_conn then
		self.__reapply_conn:Disconnect()
		self.__reapply_conn = nil
	end
end

function FFlagInjector:attach_ui(__library: any): ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	self.__library = __library

	local __self = self
	local __tab = __library:create_tab('FFlags', 'rbxassetid://10723407389')
	local __pastebox: any = nil
	local __name_box: any = nil
	local __value_box: any = nil

	local function __read_paste(): string
		if __pastebox and type(__pastebox.Get) == 'function' then
			local __ok, __t = pcall(function()
				return __pastebox:Get()
			end)

			if __ok and type(__t) == 'string' and __trim(__t) ~= '' then
				return __t
			end
		end

		return __self.__paste_buf or ''
	end

	local function __run_batch(__raw: string)
		if __self.__busy then
			__notify(__self, 'already applying…', 'warn')

			return
		end

		local __text = __trim(__raw)

		if __text == '' then
			__notify(__self, 'paste is empty', 'warn')

			return
		end

		__self.__paste_buf = __text
		__self.__busy = true

		local __preview = __parse_batch(__text)
		__notify(__self, 'applying ' .. tostring(#__preview) .. ' flags…', 'normal')

		task.spawn(function()
			local __ok, __summary = pcall(function()
				return __self:apply_batch(__text)
			end)

			__self.__busy = false

			if not __ok then
				__notify(__self, 'batch crash guarded · ' .. tostring(__summary), 'error')

				return
			end

			local __s = __summary :: FFlagBatchSummary
			local __msg = string.format(
				'batch · ok %d · fail %d · skip %d · total %d',
				__s.ok,
				__s.fail,
				__s.skipped,
				__s.total
			)

			__notify(
				__self,
				__msg,
				if __s.ok > 0 and __s.fail == 0 then 'normal' elseif __s.ok > 0 then 'warn' else 'error'
			)
		end)
	end

	__tab:create_divider('Status')

	__tab:create_button({
		title = 'Backend: ' .. (if __self.__ready then __self.__backend else 'UNSUPPORTED'),
		callback = function()
			local __b = __self:probe()
			local __list = table.concat(__self.__backends, ', ')

			if __list == '' then
				__list = 'none'
			end

			__notify(__self, 'backend · ' .. __b .. ' · [' .. __list .. ']', if __b ~= 'none' then 'normal' else 'error')
		end,
	})

	__tab:create_divider('Paste many flags')

	if type(__tab.create_pastebox) == 'function' then
		__pastebox = __tab:create_pastebox({
			title = 'JSON / list paste',
			placeholder = '{\n  "FFlagExample": true,\n  "DFIntExample": 999\n}',
			height = 160,
			callback = function(__text)
				-- live buffer — no Enter needed
				__self.__paste_buf = __text
			end,
		})
	else
		-- fallback if old UI packed without pastebox
		__tab:create_textbox({
			title = 'Batch',
			placeholder = 'paste JSON then Apply',
			callback = function(__text)
				__self.__paste_buf = __text
			end,
		})
	end

	__tab:create_button({
		title = 'Apply pasted batch (safe)',
		callback = function()
			local __raw = __read_paste()

			if __trim(__raw) == '' then
				__notify(__self, 'paste flags in the box above first', 'warn')

				return
			end

			__run_batch(__raw)
		end,
	})

	__tab:create_button({
		title = 'Clear paste box',
		callback = function()
			if __pastebox and type(__pastebox.Clear) == 'function' then
				__pastebox:Clear()
			end

			__self.__paste_buf = ''
			__notify(__self, 'paste cleared')
		end,
	})

	__tab:create_button({
		title = 'Re-apply last buffer',
		callback = function()
			local __raw = __read_paste()

			if __trim(__raw) == '' and __trim(__self.__paste_buf) ~= '' then
				__raw = __self.__paste_buf
			end

			if __trim(__raw) == '' then
				__notify(__self, 'no buffer', 'warn')

				return
			end

			__run_batch(__raw)
		end,
	})

	__tab:create_divider('Single flag')

	__name_box = __tab:create_textbox({
		title = 'Name',
		placeholder = 'DFIntTaskSchedulerTargetFps',
		callback = function(__text)
			__self.__custom_name = __trim(__text)
		end,
	})

	__value_box = __tab:create_textbox({
		title = 'Value',
		placeholder = 'true / false / 9999',
		callback = function(__text)
			__self.__custom_value = __trim(__text)
		end,
	})

	__tab:create_button({
		title = 'Inject single (live)',
		callback = function()
			local __n = __self.__custom_name
			local __v = __self.__custom_value

			if __name_box and type(__name_box.Get) == 'function' then
				local __okn, __tn = pcall(function()
					return __name_box:Get()
				end)

				if __okn and type(__tn) == 'string' and __trim(__tn) ~= '' then
					__n = __trim(__tn)
					__self.__custom_name = __n
				end
			end

			if __value_box and type(__value_box.Get) == 'function' then
				local __okv, __tv = pcall(function()
					return __value_box:Get()
				end)

				if __okv and type(__tv) == 'string' and __trim(__tv) ~= '' then
					__v = __trim(__tv)
					__self.__custom_value = __v
				end
			end

			if __n == '' or __v == '' then
				__notify(__self, 'name + value required', 'warn')

				return
			end

			if __self.__busy then
				return
			end

			__self.__busy = true

			task.spawn(function()
				local __res = __self:set(__n, __v, { verify = true, save_original = true, retries = 2 })
				__self.__busy = false

				if __res.ok then
					__notify(__self, 'ok · ' .. __n .. ' = ' .. tostring(__res.after) .. ' · ' .. tostring(__res.backend))
				else
					__notify(__self, tostring(__res.err or 'fail'), 'error')
				end
			end)
		end,
	})

	__tab:create_button({
		title = 'Read single',
		callback = function()
			local __n = __self.__custom_name

			if __name_box and type(__name_box.Get) == 'function' then
				local __okn, __tn = pcall(function()
					return __name_box:Get()
				end)

				if __okn and type(__tn) == 'string' and __trim(__tn) ~= '' then
					__n = __trim(__tn)
				end
			end

			if __n == '' then
				__notify(__self, 'set name first', 'warn')

				return
			end

			local __ok, __val = __self:get(__n)

			if __ok then
				__notify(__self, __n .. ' = ' .. tostring(__val))
			else
				__notify(__self, 'unreadable · ' .. __n, 'warn')
			end
		end,
	})

	__tab:create_divider('Safety')

	__tab:create_module({
		title = 'Safe mode (chunked + reinforce)',
		default = true,
		callback = function(__state)
			__self.__safe_mode = __state and true or false
			__notify(__self, if __self.__safe_mode then 'safe on' else 'safe off · faster')
		end,
	})

	__tab:create_module({
		title = 'Keep pinned (re-apply)',
		default = true,
		callback = function(__state)
			__self.__auto_reapply = __state and true or false
			__notify(__self, if __self.__auto_reapply then 'pin on' else 'pin off')
		end,
	})

	__tab:create_button({
		title = 'Restore all this session',
		callback = function()
			if __self.__busy then
				return
			end

			__self.__busy = true

			task.spawn(function()
				local __summary = __self:restore_all()
				__self.__busy = false
				__notify(__self, 'restore · ok ' .. tostring(__summary.ok) .. ' · fail ' .. tostring(__summary.fail))
			end)
		end,
	})

	__tab:create_button({
		title = 'Show applied count',
		callback = function()
			local __n = 0

			for _ in pairs(__self.__applied) do
				__n += 1
			end

			__notify(__self, 'pinned · ' .. tostring(__n) .. ' · backend ' .. __self.__backend)
		end,
	})
end

function FFlagInjector:destroy(): ()
	self:stop()
	self.__library = nil
end


export type ComboMode = 'hold' | 'toggle' | 'tap'

export type ComboDef = {
	id: string,
	label: string,
	desc: string,
	key: Enum.KeyCode,
	mode: ComboMode,
	enabled: boolean,
	active: boolean,
	actions_on: { any },
	actions_off: { any },
}

export type Combos = {
	__master: boolean,
	__defs: { ComboDef },
	__by_id: { [string]: ComboDef },
	__listening_id: string?,
	__conn_began: RBXScriptConnection?,
	__conn_ended: RBXScriptConnection?,
	__bind_conn: RBXScriptConnection?,
	__library: any,
	__ctx: any,

	init: (self: Combos) -> Combos,
	set_context: (self: Combos, ctx: any) -> (),
	set_master: (self: Combos, state: boolean) -> (),
	set_key: (self: Combos, id: string, key: Enum.KeyCode) -> (),
	set_combo_enabled: (self: Combos, id: string, state: boolean) -> (),
	run_on: (self: Combos, id: string) -> (),
	run_off: (self: Combos, id: string) -> (),
	all_off: (self: Combos) -> (),
	start: (self: Combos) -> (),
	stop: (self: Combos) -> (),
	attach_ui: (self: Combos, library: any) -> (),
	destroy: (self: Combos) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local Players = Service.Players
local UserInputService = Service.UserInputService
local LocalPlayer = Players.LocalPlayer

local Combos: Combos = {
	__master = true,
	__defs = {},
	__by_id = {},
	__listening_id = nil,
	__conn_began = nil,
	__conn_ended = nil,
	__bind_conn = nil,
	__library = nil,
	__ctx = {},
}
Combos.__index = Combos

local function __notify(__self: Combos, __msg: string, __kind: string?): ()
	local __lib = __self.__library

	if type(__lib) == 'table' and type(__lib.notify) == 'function' then
		pcall(function()
			__lib:notify({
				title = 'Combos',
				content = __msg,
				duration = 2.2,
				notify_type = __kind or 'normal',
			})
		end)
	end
end

local function __backpack(): Instance?
	return LocalPlayer:FindFirstChild('Backpack')
end

local function __set_value(__name: string, __value: any): boolean
	local __pack = __backpack()

	if not __pack then
		return false
	end

	local __v = __pack:FindFirstChild(__name)

	if not __v then
		return false
	end

	local __ok = pcall(function()
		(__v :: any).Value = __value
	end)

	return __ok
end

local function __get_value(__name: string): any
	local __pack = __backpack()

	if not __pack then
		return nil
	end

	local __v = __pack:FindFirstChild(__name)

	if not __v then
		return nil
	end

	local __ok, __val = pcall(function()
		return (__v :: any).Value
	end)

	if __ok then
		return __val
	end

	return nil
end

local function __tap_key(__key: Enum.KeyCode, __down: boolean): ()
	local __ok = pcall(function()
		local __vim = game:GetService('VirtualInputManager')
		__vim:SendKeyEvent(__down, __key, false, game)
	end)

	if __ok then
		return
	end

	-- fallback: some executors expose keypress/keyrelease
	pcall(function()
		if __down and type(keypress) == 'function' then
			keypress(__key)
		elseif (not __down) and type(keyrelease) == 'function' then
			keyrelease(__key)
		end
	end)
end

local function __module_set(__ctx: any, __name: string, __state: boolean): ()
	local __mod = __ctx[__name]

	if type(__mod) ~= 'table' then
		return
	end

	if __name == 'Gk' then
		if __state then
			if type(__mod.set_reach) == 'function' then
				__mod:set_reach(true)
			end

			if type(__mod.set_stop) == 'function' then
				__mod:set_stop(true)
			end
		else
			if type(__mod.set_reach) == 'function' then
				__mod:set_reach(false)
			end

			if type(__mod.set_stop) == 'function' then
				__mod:set_stop(false)
			end
		end

		return
	end

	if type(__mod.set_enabled) == 'function' then
		__mod:set_enabled(__state)
	end
end

local function __run_actions(__self: Combos, __actions: { any }): ()
	local __ctx = __self.__ctx or {}

	for _, __a in ipairs(__actions) do
		local __t = __a.type

		local __ok, __err = pcall(function()
			if __t == 'module' then
				__module_set(__ctx, __a.name, __a.state and true or false)
			elseif __t == 'backpack' then
				__set_value(__a.name, __a.value)
			elseif __t == 'backpack_save' then
				-- store previous in action table
				__a._prev = __get_value(__a.name)
				__set_value(__a.name, __a.value)
			elseif __t == 'backpack_restore' then
				if __a._prev ~= nil then
					__set_value(__a.name, __a._prev)
					__a._prev = nil
				elseif __a.fallback ~= nil then
					__set_value(__a.name, __a.fallback)
				end
			elseif __t == 'key' then
				local __key = __a.key
				local __hold = tonumber(__a.hold) or 0.05

				__tap_key(__key, true)

				if __hold > 0 then
					task.wait(__hold)
				end

				__tap_key(__key, false)
			elseif __t == 'key_down' then
				__tap_key(__a.key, true)
			elseif __t == 'key_up' then
				__tap_key(__a.key, false)
			elseif __t == 'panic' then
				local __p = __ctx.Panic

				if type(__p) == 'table' and type(__p.trigger) == 'function' then
					__p:trigger()
				end
			end
		end)

		if not __ok then
			warn('[euphoria combos] action ' .. tostring(__t) .. ' · ' .. tostring(__err))
		end
	end
end

local function __make_defaults(): { ComboDef }
	return {
		{
			id = 'field_pressure',
			label = 'Field pressure',
			desc = 'Reach + BallReach + Reacts',
			key = Enum.KeyCode.Q,
			mode = 'hold',
			enabled = true,
			active = false,
			actions_on = {
				{ type = 'module', name = 'Reach', state = true },
				{ type = 'module', name = 'BallReach', state = true },
				{ type = 'module', name = 'Reacts', state = true },
			},
			actions_off = {
				{ type = 'module', name = 'Reach', state = false },
				{ type = 'module', name = 'BallReach', state = false },
				{ type = 'module', name = 'Reacts', state = false },
			},
		},
		{
			id = 'curve_power',
			label = 'Curve + Power',
			desc = 'Backpack Curving + PowerActive (hold)',
			key = Enum.KeyCode.E,
			mode = 'hold',
			enabled = true,
			active = false,
			actions_on = {
				{ type = 'backpack_save', name = 'Curving', value = 1 },
				{ type = 'backpack_save', name = 'PowerActive', value = true },
			},
			actions_off = {
				{ type = 'backpack_restore', name = 'Curving', fallback = 0 },
				{ type = 'backpack_restore', name = 'PowerActive', fallback = false },
			},
		},
		{
			id = 'header_pack',
			label = 'Header pack',
			desc = 'AutoHeader + Reacts',
			key = Enum.KeyCode.H,
			mode = 'toggle',
			enabled = true,
			active = false,
			actions_on = {
				{ type = 'module', name = 'AutoHeader', state = true },
				{ type = 'module', name = 'Reacts', state = true },
			},
			actions_off = {
				{ type = 'module', name = 'AutoHeader', state = false },
				{ type = 'module', name = 'Reacts', state = false },
			},
		},
		{
			id = 'gk_lock',
			label = 'GK lock',
			desc = 'GK reach box + freno seco',
			key = Enum.KeyCode.G,
			mode = 'toggle',
			enabled = true,
			active = false,
			actions_on = {
				{ type = 'module', name = 'Gk', state = true },
			},
			actions_off = {
				{ type = 'module', name = 'Gk', state = false },
			},
		},
		{
			id = 'react_burst',
			label = 'React burst',
			desc = 'Reacts ON + tap F (game react)',
			key = Enum.KeyCode.F,
			mode = 'tap',
			enabled = true,
			active = false,
			actions_on = {
				{ type = 'module', name = 'Reacts', state = true },
				{ type = 'key', key = Enum.KeyCode.F, hold = 0.04 },
			},
			actions_off = {},
		},
		{
			id = 'react_x',
			label = 'React X window',
			desc = 'Reacts ON + tap X',
			key = Enum.KeyCode.X,
			mode = 'tap',
			enabled = true,
			active = false,
			actions_on = {
				{ type = 'module', name = 'Reacts', state = true },
				{ type = 'key', key = Enum.KeyCode.X, hold = 0.04 },
			},
			actions_off = {},
		},
		{
			id = 'speed_burst',
			label = 'Speed burst',
			desc = 'Backpack Speed 36 while held (restore after)',
			key = Enum.KeyCode.LeftShift,
			mode = 'hold',
			enabled = false, -- off by default — riskier
			active = false,
			actions_on = {
				{ type = 'backpack_save', name = 'Speed', value = 36 },
			},
			actions_off = {
				{ type = 'backpack_restore', name = 'Speed', fallback = 30 },
			},
		},
		{
			id = 'full_offense',
			label = 'Full offense',
			desc = 'Reach + BallReach + Reacts + Header (toggle)',
			key = Enum.KeyCode.V,
			mode = 'toggle',
			enabled = true,
			active = false,
			actions_on = {
				{ type = 'module', name = 'Reach', state = true },
				{ type = 'module', name = 'BallReach', state = true },
				{ type = 'module', name = 'Reacts', state = true },
				{ type = 'module', name = 'AutoHeader', state = true },
			},
			actions_off = {
				{ type = 'module', name = 'Reach', state = false },
				{ type = 'module', name = 'BallReach', state = false },
				{ type = 'module', name = 'Reacts', state = false },
				{ type = 'module', name = 'AutoHeader', state = false },
			},
		},
	}
end

function Combos:init(): Combos
	self.__master = true
	self.__defs = __make_defaults()
	self.__by_id = {}
	self.__listening_id = nil
	self.__library = nil
	self.__ctx = {}

	for _, __d in ipairs(self.__defs) do
		self.__by_id[__d.id] = __d
	end

	return self
end

function Combos:set_context(__ctx: any): ()
	self.__ctx = __ctx or {}
end

function Combos:set_master(__state: boolean): ()
	self.__master = __state and true or false

	if not self.__master then
		self:all_off()
	end
end

function Combos:set_key(__id: string, __key: Enum.KeyCode): ()
	local __d = self.__by_id[__id]

	if not __d then
		return
	end

	__d.key = __key
end

function Combos:set_combo_enabled(__id: string, __state: boolean): ()
	local __d = self.__by_id[__id]

	if not __d then
		return
	end

	__d.enabled = __state and true or false

	if not __d.enabled and __d.active then
		self:run_off(__id)
	end
end

function Combos:run_on(__id: string): ()
	local __d = self.__by_id[__id]

	if not __d or not __d.enabled then
		return
	end

	__run_actions(self, __d.actions_on)
	__d.active = true
end

function Combos:run_off(__id: string): ()
	local __d = self.__by_id[__id]

	if not __d then
		return
	end

	if #__d.actions_off > 0 then
		__run_actions(self, __d.actions_off)
	end

	__d.active = false
end

function Combos:all_off(): ()
	for _, __d in ipairs(self.__defs) do
		if __d.active then
			self:run_off(__d.id)
		end
	end
end

function Combos:start(): ()
	if self.__conn_began then
		return
	end

	self.__conn_began = UserInputService.InputBegan:Connect(function(__input, __gpe)
		if __gpe or not self.__master then
			return
		end

		if self.__listening_id then
			return
		end

		if __input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		for _, __d in ipairs(self.__defs) do
			if not __d.enabled then
				continue
			end

			if __input.KeyCode ~= __d.key then
				continue
			end

			if __d.mode == 'hold' then
				self:run_on(__d.id)
				__notify(self, __d.label .. ' · HOLD', 'normal')
			elseif __d.mode == 'toggle' then
				if __d.active then
					self:run_off(__d.id)
					__notify(self, __d.label .. ' · OFF', 'warn')
				else
					self:run_on(__d.id)
					__notify(self, __d.label .. ' · ON', 'normal')
				end
			elseif __d.mode == 'tap' then
				self:run_on(__d.id)
				__notify(self, __d.label .. ' · TAP', 'normal')
			end
		end
	end)

	self.__conn_ended = UserInputService.InputEnded:Connect(function(__input, __gpe)
		if not self.__master then
			return
		end

		if __input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		for _, __d in ipairs(self.__defs) do
			if __d.mode == 'hold' and __d.active and __input.KeyCode == __d.key then
				self:run_off(__d.id)
			end
		end
	end)
end

function Combos:stop(): ()
	self:all_off()

	if self.__conn_began then
		self.__conn_began:Disconnect()
		self.__conn_began = nil
	end

	if self.__conn_ended then
		self.__conn_ended:Disconnect()
		self.__conn_ended = nil
	end

	if self.__bind_conn then
		self.__bind_conn:Disconnect()
		self.__bind_conn = nil
	end

	self.__listening_id = nil
end

function Combos:attach_ui(__library: any): ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	self.__library = __library

	local __self = self
	local __tab = __library:create_tab('Combos', 'rbxassetid://10709781912')
	local __bind_buttons: { [string]: any } = {}

	__tab:create_divider('Master')

	__tab:create_module({
		title = 'Combos enabled',
		default = true,
		callback = function(__state)
			__self:set_master(__state)
			__notify(__self, if __state then 'combos on' else 'combos off')
		end,
	})

	__tab:create_button({
		title = 'Release all active holds/toggles',
		callback = function()
			__self:all_off()
			__notify(__self, 'all combos released', 'warn')
		end,
	})

	__tab:create_divider('Macros · click bind to set key')

	for _, __d in ipairs(__self.__defs) do
		local __id = __d.id

		__tab:create_module({
			title = __d.label .. ' [' .. __d.mode .. ']',
			default = __d.enabled,
			callback = function(__state)
				__self:set_combo_enabled(__id, __state)
			end,
		})

		__tab:create_button({
			title = 'Bind · ' .. __d.key.Name .. ' · ' .. __d.desc,
			callback = function()
				if __self.__listening_id then
					return
				end

				__self.__listening_id = __id
				__notify(__self, 'press key for · ' .. __d.label)

				if __self.__bind_conn then
					__self.__bind_conn:Disconnect()
					__self.__bind_conn = nil
				end

				__self.__bind_conn = UserInputService.InputBegan:Connect(function(__input, __gpe)
					if __gpe then
						return
					end

					if __input.UserInputType ~= Enum.UserInputType.Keyboard then
						return
					end

					-- ignore Escape as cancel
					if __input.KeyCode == Enum.KeyCode.Escape then
						__self.__listening_id = nil

						if __self.__bind_conn then
							__self.__bind_conn:Disconnect()
							__self.__bind_conn = nil
						end

						__notify(__self, 'bind cancelled', 'warn')

						return
					end

					__self:set_key(__id, __input.KeyCode)
					__self.__listening_id = nil

					if __self.__bind_conn then
						__self.__bind_conn:Disconnect()
						__self.__bind_conn = nil
					end

					__notify(__self, __d.label .. ' → ' .. __input.KeyCode.Name)
				end)
			end,
		})
	end

	__tab:create_divider('Modes')
	__tab:create_button({
		title = 'hold = keep pressed · toggle = on/off · tap = once',
		callback = function()
			__notify(__self, 'hold / toggle / tap', 'normal')
		end,
	})
end

function Combos:destroy(): ()
	self:stop()
	self.__library = nil
	self.__ctx = {}
end


export type Panic = {
	__key: Enum.KeyCode,
	__listening: boolean,
	__conn: RBXScriptConnection?,
	__bind_conn: RBXScriptConnection?,
	__handlers: { { name: string, off: () -> () } },
	__library: any,

	init: (self: Panic) -> Panic,
	register: (self: Panic, name: string, off: () -> ()) -> (),
	trigger: (self: Panic) -> number,
	set_key: (self: Panic, key: Enum.KeyCode) -> (),
	start: (self: Panic) -> (),
	stop: (self: Panic) -> (),
	attach_ui: (self: Panic, library: any) -> (),
	destroy: (self: Panic) -> (),
}

local Service = setmetatable({} :: any, {
	__index = function(self: any, name: string): Instance
		rawset(self, name, (cloneref or (function(...) return ... end))(game:GetService(name)))

		return rawget(self, name)
	end
})

local UserInputService = Service.UserInputService

local Panic: Panic = {
	__key = Enum.KeyCode.End,
	__listening = false,
	__conn = nil,
	__bind_conn = nil,
	__handlers = {},
	__library = nil,
}
Panic.__index = Panic

local function __notify(__self: Panic, __msg: string, __kind: string?): ()
	local __lib = __self.__library

	if type(__lib) == 'table' and type(__lib.notify) == 'function' then
		pcall(function()
			__lib:notify({
				title = 'Panic',
				content = __msg,
				duration = 2.5,
				notify_type = __kind or 'normal',
			})
		end)
	end
end

function Panic:init(): Panic
	self.__key = Enum.KeyCode.End
	self.__listening = false
	self.__handlers = {}
	self.__library = nil

	return self
end

function Panic:register(__name: string, __off: () -> ()): ()
	if type(__off) ~= 'function' then
		return
	end

	-- replace if same name
	for __i, __h in ipairs(self.__handlers) do
		if __h.name == __name then
			self.__handlers[__i] = { name = __name, off = __off }

			return
		end
	end

	table.insert(self.__handlers, { name = __name, off = __off })
end

function Panic:trigger(): number
	local __n = 0

	for _, __h in ipairs(self.__handlers) do
		local __ok, __err = pcall(__h.off)

		if __ok then
			__n += 1
		else
			warn('[euphoria panic] ' .. __h.name .. ' · ' .. tostring(__err))
		end
	end

	-- hide UI if possible
	local __lib = self.__library

	if type(__lib) == 'table' then
		pcall(function()
			if type(__lib.__toggle_window) == 'function' and not __lib.__minimized then
				__lib.__toggle_window()
			end
		end)
	end

	__notify(self, 'OFF · ' .. tostring(__n) .. ' modules killed', 'warn')
	print('[euphoria] PANIC OFF · ' .. tostring(__n) .. ' handlers')

	return __n
end

function Panic:set_key(__key: Enum.KeyCode): ()
	self.__key = __key
end

function Panic:start(): ()
	if self.__conn then
		return
	end

	self.__conn = UserInputService.InputBegan:Connect(function(__input, __gpe)
		if __gpe then
			return
		end

		if self.__listening then
			return
		end

		if __input.KeyCode == self.__key then
			self:trigger()
		end
	end)
end

function Panic:stop(): ()
	if self.__conn then
		self.__conn:Disconnect()
		self.__conn = nil
	end

	if self.__bind_conn then
		self.__bind_conn:Disconnect()
		self.__bind_conn = nil
	end

	self.__listening = false
end

function Panic:attach_ui(__library: any): ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	self.__library = __library

	local __self = self
	local __tab = __library:create_tab('Panic', 'rbxassetid://10747384394')

	__tab:create_divider('Kill switch')

	__tab:create_button({
		title = 'PANIC OFF NOW',
		callback = function()
			__self:trigger()
		end,
	})

	__tab:create_button({
		title = 'Bind key: ' .. __self.__key.Name .. ' (click)',
		callback = function()
			if __self.__listening then
				return
			end

			__self.__listening = true
			__notify(__self, 'press any key for panic…', 'normal')

			if __self.__bind_conn then
				__self.__bind_conn:Disconnect()
				__self.__bind_conn = nil
			end

			__self.__bind_conn = UserInputService.InputBegan:Connect(function(__input, __gpe)
				if __gpe then
					return
				end

				if __input.UserInputType ~= Enum.UserInputType.Keyboard then
					return
				end

				__self:set_key(__input.KeyCode)
				__self.__listening = false

				if __self.__bind_conn then
					__self.__bind_conn:Disconnect()
					__self.__bind_conn = nil
				end

				__notify(__self, 'panic key · ' .. __input.KeyCode.Name)
			end)
		end,
	})

	__tab:create_divider('What it does')
	__tab:create_button({
		title = 'Disables all registered cheats + hides UI',
		callback = function()
			local __n = #__self.__handlers
			__notify(__self, tostring(__n) .. ' handlers · key ' .. __self.__key.Name)
		end,
	})

	__tab:create_divider('Combos (idea)')
	__tab:create_button({
		title = 'Combo = 1 tecla hace 2–3 acciones',
		callback = function()
			__notify(__self, 'ej: Q = curve+power · no implementado aún', 'normal')
		end,
	})
end

function Panic:destroy(): ()
	self:stop()
	self.__handlers = {}
	self.__library = nil
end


export type Config = {
	init: (self: Config) -> Config,
	attach_ui: (self: Config, library: any) -> (),
}

local Config : Config = {}
Config.__index = Config

function Config:init() : Config
	return self
end

function Config:attach_ui(__library : any) : ()
	if type(__library) ~= 'table' or type(__library.create_tab) ~= 'function' then
		return
	end

	if type(__library.get_device) == 'function' then
		__library:get_device()
	end

	local UserInputService = game:GetService('UserInputService')
	local __device = __library.__device or 'unknown'
	local __is_mobile = __device == 'mobile' or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
	local __device_label = __is_mobile and 'Mobile' or ((__device == 'pc' and 'PC') or 'PC')

	local __tab = __library:create_tab('Config', 'rbxassetid://10734943674')

	__tab:create_divider('Device')
	__tab:create_button({
		title = 'Detected: ' .. __device_label,
		callback = function()
			if type(__library.get_device) == 'function' then
				__library:get_device()
			end

			if __library.notify then
				__library:notify({
					title = 'Config',
					content = 'device · ' .. __device_label,
					duration = 2,
					notify_type = 'normal',
				})
			end
		end,
	})

	__tab:create_divider('UI')

	local __key_name = 'RightControl'

	if __library.__toggle_key then
		__key_name = __library.__toggle_key.Name
	end

	if not __is_mobile then
		__tab:create_button({
			title = 'Toggle key: ' .. __key_name .. ' (click to set)',
			callback = function()
				if __library.notify then
					__library:notify({
						title = 'Config',
						content = 'press any key...',
						duration = 2,
						notify_type = 'normal',
					})
				end

				local __conn
				__conn = UserInputService.InputBegan:Connect(function(__input, __gpe)
					if __gpe then
						return
					end

					if __input.UserInputType ~= Enum.UserInputType.Keyboard then
						return
					end

					__library.__toggle_key = __input.KeyCode

					if __library.notify then
						__library:notify({
							title = 'Config',
							content = 'toggle key · ' .. __input.KeyCode.Name,
							duration = 2.5,
							notify_type = 'normal',
						})
					end

					if __conn then
						__conn:Disconnect()
					end
				end)
			end,
		})
	end

	__tab:create_button({
		title = 'Hide / show UI now',
		callback = function()
			if type(__library.__toggle_window) == 'function' then
				__library.__toggle_window()
			end
		end,
	})

	__tab:create_divider('Tip')
	__tab:create_button({
		title = __is_mobile and 'Drag black E button · tap to open/close' or 'Use keybind (default RightControl) to toggle',
		callback = function() end,
	})
end


local function __clean_old()
	local __cg = game:GetService('CoreGui')
	local __old = __cg:FindFirstChild('Euphoria')

	if __old then
		__old:Destroy()
	end

	local __cam = workspace.CurrentCamera

	if __cam then
		for _, __c in ipairs(__cam:GetChildren()) do
			if __c.Name == '__euphoria_reach_ring' then
				__c:Destroy()
			end
		end
	end
end

local function __boot()
	__clean_old()

	if type(Library) ~= 'table' or type(Library.init) ~= 'function' then
		error('[euphoria] Library missing — rebuild dist/euphoria.luau')
	end

	if type(AntiTamper) == 'table' then
		AntiTamper:init()
		AntiTamper:start()
	end

	if type(AcBypass) == 'table' then
		AcBypass:init()
		AcBypass:start()
	end

	if type(Console) == 'table' and type(Console.init) == 'function' then
		task.spawn(function()
			Console:init({ brand = 'Euphoria', delay = 0.03 })
			Console:run()
		end)
	end

	Library:init('euphoria')

	if type(Reach) == 'table' then
		Reach:init()
		Reach:set_enabled(false)
		Reach:attach_ui(Library)
		Reach:start()
	end

	if type(BallReach) == 'table' then
		BallReach:init()
		BallReach:set_enabled(false)
		BallReach:attach_ui(Library)
		BallReach:start()
	end

	if type(Gk) == 'table' then
		Gk:init()
		Gk:attach_ui(Library)
		Gk:start()
	end

	if type(AutoHeader) == 'table' then
		AutoHeader:init()
		AutoHeader:set_enabled(false)
		AutoHeader:attach_ui(Library)
		AutoHeader:start()
	end

	if type(PingChanger) == 'table' then
		PingChanger:init()
		PingChanger:set_enabled(false)
		PingChanger:attach_ui(Library)
		PingChanger:start()
	end

	if type(Reacts) == 'table' then
		Reacts:init()
		Reacts:set_enabled(false)
		Reacts:attach_ui(Library)
		Reacts:start()
	end

	if type(AvatarStealer) == 'table' then
		AvatarStealer:init()
		AvatarStealer:attach_ui(Library)
		AvatarStealer:start()
	end

	if type(FFlagInjector) == 'table' then
		FFlagInjector:init()
		FFlagInjector:attach_ui(Library)
		FFlagInjector:start()
	end

	if type(Config) == 'table' then
		Config:init()
		Config:attach_ui(Library)
	end

	if type(Combos) == 'table' then
		Combos:init()
		Combos:set_context({
			Reach = Reach,
			BallReach = BallReach,
			Gk = Gk,
			AutoHeader = AutoHeader,
			Reacts = Reacts,
			PingChanger = PingChanger,
			Panic = Panic,
		})
		Combos:attach_ui(Library)
		Combos:start()
	end

	if type(Panic) == 'table' then
		Panic:init()

		if type(Reach) == 'table' and type(Reach.set_enabled) == 'function' then
			Panic:register('Reach', function()
				Reach:set_enabled(false)
			end)
		end

		if type(BallReach) == 'table' and type(BallReach.set_enabled) == 'function' then
			Panic:register('BallReach', function()
				BallReach:set_enabled(false)
			end)
		end

		if type(Gk) == 'table' then
			Panic:register('Gk', function()
				if type(Gk.set_reach) == 'function' then
					Gk:set_reach(false)
				end

				if type(Gk.set_stop) == 'function' then
					Gk:set_stop(false)
				end
			end)
		end

		if type(AutoHeader) == 'table' and type(AutoHeader.set_enabled) == 'function' then
			Panic:register('AutoHeader', function()
				AutoHeader:set_enabled(false)
			end)
		end

		if type(Reacts) == 'table' and type(Reacts.set_enabled) == 'function' then
			Panic:register('Reacts', function()
				Reacts:set_enabled(false)
			end)
		end

		if type(PingChanger) == 'table' and type(PingChanger.set_enabled) == 'function' then
			Panic:register('Ping', function()
				PingChanger:set_enabled(false)
			end)
		end

		if type(FFlagInjector) == 'table' then
			Panic:register('FFlags', function()
				if type(FFlagInjector) == 'table' then
					FFlagInjector.__auto_reapply = false
					FFlagInjector.__busy = false
				end
			end)
		end

		if type(Combos) == 'table' then
			Panic:register('Combos', function()
				if type(Combos.all_off) == 'function' then
					Combos:all_off()
				end

				if type(Combos.set_master) == 'function' then
					Combos:set_master(false)
				end
			end)

			-- refresh panic ref inside combos context
			if type(Combos.set_context) == 'function' then
				Combos:set_context({
					Reach = Reach,
					BallReach = BallReach,
					Gk = Gk,
					AutoHeader = AutoHeader,
					Reacts = Reacts,
					PingChanger = PingChanger,
					Panic = Panic,
				})
			end
		end

		Panic:attach_ui(Library)
		Panic:start()
	end

	if type(AntiTamper) == 'table' then
		AntiTamper:seal()
	end

	Library:notify({
		title = 'Euphoria',
		content = 'loaded · panic key End',
		duration = 3,
		notify_type = 'normal',
	})

	print('[euphoria] boot OK')
end

local __ok, __err = pcall(__boot)

if not __ok then
	warn('[euphoria] boot ERROR: ' .. tostring(__err))
end
