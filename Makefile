# Airis Makefile
# Swift CLI 工具构建和测试脚本

.PHONY: help build test test-quick test-perf install clean format lint

.DEFAULT_GOAL := help

# 配置
BINARY_NAME = airis
INSTALL_PATH = $(HOME)/.local/bin
BUILD_PATH = .build/release

## help: 显示帮助信息
help:
	@echo "Airis - Makefile 命令"
	@echo ""
	@echo "构建命令："
	@echo "  make build         编译 debug 版本"
	@echo "  make release       编译 release 版本"
	@echo "  make install       安装到 ~/.local/bin"
	@echo ""
	@echo "测试命令："
	@echo "  make test          运行完整测试（~101s，包含性能测试）"
	@echo "  make test-quick    快速测试（~30-40s，跳过性能测试）⚡"
	@echo "  make test-perf     仅运行性能测试"
	@echo "  make test-unit     仅运行单元测试"
	@echo "  make test-integration  仅运行集成测试"
	@echo ""
	@echo "工具命令："
	@echo "  make clean         清理构建产物"
	@echo "  make format        格式化代码（需要 swiftformat）"
	@echo "  make lint          代码检查（需要 swiftlint）"
	@echo ""

## build: 编译 debug 版本
build:
	@echo "🔨 编译 debug 版本..."
	swift build

## release: 编译 release 版本
release:
	@echo "🚀 编译 release 版本..."
	swift build -c release

## install: 安装到 ~/.local/bin
install: release
	@echo "📦 安装 $(BINARY_NAME) 到 $(INSTALL_PATH)..."
	@mkdir -p $(INSTALL_PATH)
	@cp -f $(BUILD_PATH)/$(BINARY_NAME) $(INSTALL_PATH)/
	@echo "✅ 安装完成: $(INSTALL_PATH)/$(BINARY_NAME)"
	@echo ""
	@echo "验证安装:"
	@$(INSTALL_PATH)/$(BINARY_NAME) --version

## test: 运行完整测试（包含性能测试，~101s）
test:
	@echo "🧪 运行完整测试套件（640 tests）..."
	@echo "⏱️  预计耗时: ~101 秒"
	@echo ""
	swift test --parallel

## test-quick: 快速测试（跳过性能测试，~30-40s）⚡
test-quick:
	@echo "⚡ 运行快速测试（跳过性能测试）..."
	@echo "⏱️  预计耗时: ~30-40 秒"
	@echo ""
	swift test --parallel \
		--skip VisionPerformanceTests \
		--skip ImageIOPerformanceTests \
		--skip CoreImagePerformanceTests

## test-perf: 仅运行性能测试
test-perf:
	@echo "📊 运行性能测试..."
	swift test --parallel \
		--filter VisionPerformanceTests \
		--filter ImageIOPerformanceTests \
		--filter CoreImagePerformanceTests

## test-unit: 仅运行单元测试
test-unit:
	@echo "🧪 运行单元测试..."
	swift test --parallel \
		--skip Integration \
		--skip Performance \
		--skip EdgeCases

## test-integration: 仅运行集成测试
test-integration:
	@echo "🔗 运行集成测试..."
	swift test --parallel --filter Integration

## clean: 清理构建产物
clean:
	@echo "🧹 清理构建产物..."
	rm -rf .build
	@echo "✅ 清理完成"

## format: 格式化代码（需要 swiftformat）
format:
	@if command -v swiftformat >/dev/null 2>&1; then \
		echo "✨ 格式化代码..."; \
		swiftformat Sources/ Tests/; \
	else \
		echo "⚠️  swiftformat 未安装"; \
		echo "   安装: brew install swiftformat"; \
	fi

## lint: 代码检查（需要 swiftlint）
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "🔍 代码检查..."; \
		swiftlint; \
	else \
		echo "⚠️  swiftlint 未安装"; \
		echo "   安装: brew install swiftlint"; \
	fi

# 开发快捷命令
.PHONY: dev check

## dev: 开发模式 - 快速测试 + 编译
dev: test-quick build
	@echo "✅ 开发检查完成"

## check: 完整检查 - 测试 + 格式 + lint
check: test format lint
	@echo "✅ 完整检查通过"
