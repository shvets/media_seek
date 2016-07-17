module Utils
  def with_interrupt_handler &code
    code.call
  rescue Interrupt
    exit
  end

  def with_loop &code
    done = false

    until done do
      done = code.call
    end
  end
end