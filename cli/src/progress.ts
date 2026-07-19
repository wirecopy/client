const FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

interface ProgressState {
  label: string;
  sent?: number;
  total?: number;
}

export class TerminalProgress {
  private state: ProgressState = { label: "Working" };
  private frame = 0;
  private startedAt = Date.now();
  private timer: NodeJS.Timeout | undefined;
  private lastNonTTYLabel?: string;
  private finished = false;

  constructor(
    private readonly stream = process.stderr,
    private readonly interactive = Boolean(process.stderr.isTTY),
  ) {}

  update(label: string, sent?: number, total?: number): void {
    this.finished = false;
    this.state = {
      label,
      ...(sent !== undefined ? { sent } : {}),
      ...(total !== undefined ? { total } : {}),
    };
    if (this.interactive) {
      this.start();
      this.render();
    } else if (this.lastNonTTYLabel !== label) {
      this.stream.write(`${label}\n`);
      this.lastNonTTYLabel = label;
    }
  }

  done(label = "Published"): void {
    this.stop();
    this.finished = true;
    if (this.interactive) {
      this.stream.write(`\r\u001b[2K\u001b[32m✓\u001b[0m ${label} ${dim(elapsed(Date.now() - this.startedAt))}\n`);
    } else if (this.lastNonTTYLabel !== label) {
      this.stream.write(`${label}\n`);
      this.lastNonTTYLabel = label;
    }
  }

  clear(): void {
    this.stop();
    if (this.interactive && !this.finished) {
      this.stream.write("\r\u001b[2K");
    }
  }

  private start(): void {
    if (this.timer) {
      return;
    }
    this.timer = setInterval(() => {
      this.frame = (this.frame + 1) % FRAMES.length;
      this.render();
    }, 80);
    this.timer.unref();
  }

  private stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = undefined;
    }
  }

  private render(): void {
    this.stream.write(
      `\r\u001b[2K\u001b[36m${FRAMES[this.frame]}\u001b[0m ${formatProgressLine(this.state, Date.now() - this.startedAt)}`,
    );
  }
}

export function formatProgressLine(state: ProgressState, elapsedMs: number): string {
  const details: string[] = [];
  if (state.sent !== undefined && state.total !== undefined && state.total > 0) {
    const percentage = Math.min(100, Math.floor((state.sent / state.total) * 100));
    details.push(`${percentage}%`);
    details.push(`${formatBytes(state.sent)} / ${formatBytes(state.total)}`);
  }
  details.push(elapsed(elapsedMs));
  return `${state.label} ${dim(details.join(" · "))}`;
}

function formatBytes(value: number): string {
  if (value < 1024) {
    return `${value} B`;
  }
  const units = ["KB", "MB", "GB"];
  let size = value / 1024;
  let unit = units[0]!;
  for (let index = 1; index < units.length && size >= 1024; index += 1) {
    size /= 1024;
    unit = units[index]!;
  }
  return `${size >= 10 ? size.toFixed(0) : size.toFixed(1)} ${unit}`;
}

function elapsed(milliseconds: number): string {
  return `${(milliseconds / 1000).toFixed(1)}s`;
}

function dim(value: string): string {
  return `\u001b[2m${value}\u001b[0m`;
}
